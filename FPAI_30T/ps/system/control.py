"""RFCT client: durable IDs, identical retries, peer/echo/boot checks."""
from __future__ import annotations
from collections import Counter
import os
from pathlib import Path
import select
import socket
import sqlite3
import struct
import time

from rf_protocol import (ControlMessage, ProtocolError, Snapshot, RxInfo, STATUSES,
                         decode_control, validate_request)


class ControlError(RuntimeError):
    pass


class ControlTimeout(ControlError):
    pass


class SessionConflict(ControlError):
    """An external session must never be stopped or automatically taken over."""


class BootChanged(ControlError):
    pass


class IdStore:
    def __init__(self, path: Path):
        path.parent.mkdir(parents=True, exist_ok=True)
        self.lock = Path(str(path) + ".lock")
        fd = os.open(self.lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        os.close(fd)
        try:
            self.db = sqlite3.connect(path)
            self.db.execute("PRAGMA synchronous=FULL")
            self.db.execute("CREATE TABLE IF NOT EXISTS ids (name TEXT PRIMARY KEY, value INTEGER NOT NULL)")
            self.db.commit()
        except BaseException:
            self.lock.unlink(missing_ok=True)
            raise

    def reserve(self, name: str, floor: int = 0) -> int:
        # Commit allocation BEFORE sending. Crashes burn IDs rather than reuse.
        with self.db:
            self.db.execute("BEGIN IMMEDIATE")
            row = self.db.execute("SELECT value FROM ids WHERE name=?", (name,)).fetchone()
            value = max(row[0] if row else 0, floor) + 1
            if value > 0xffffffff:
                raise OverflowError(f"{name} u32 exhausted; cannot wrap")
            self.db.execute("INSERT OR REPLACE INTO ids VALUES (?,?)", (name, value))
        return value

    def advance(self, name: str, floor: int):
        """Persist a verified high-water without allocating/reusing an ID."""
        if not 0 <= floor <= 0xffffffff:
            raise ValueError("u32 high-water required")
        with self.db:
            self.db.execute("BEGIN IMMEDIATE")
            row = self.db.execute("SELECT value FROM ids WHERE name=?", (name,)).fetchone()
            self.db.execute("INSERT OR REPLACE INTO ids VALUES (?,?)",
                            (name, max(row[0] if row else 0, floor)))

    def ownership(self):
        return tuple(self.db.execute("SELECT value FROM ids WHERE name=?", (name,)).fetchone()[0]
                     for name in ("owner_boot", "owner_config", "owner_capture")) if self.db.execute(
                         "SELECT 1 FROM ids WHERE name='owner_capture'").fetchone() else None

    def own(self, boot: int, config: int, capture: int):
        # Record before START: a lost ACK must not make an accepted capture foreign.
        with self.db:
            for name, value in zip(("owner_boot", "owner_config", "owner_capture"), (boot, config, capture)):
                self.db.execute("INSERT OR REPLACE INTO ids VALUES (?,?)", (name, value))

    def disown(self):
        with self.db:
            self.db.execute("DELETE FROM ids WHERE name IN ('owner_boot','owner_config','owner_capture')")

    def close(self):
        self.db.close()
        self.lock.unlink()


class ControlClient:
    def __init__(self, sock: socket.socket, peer, ids: IdStore, *,
                 pump=lambda: None, uncertain=lambda: None,
                 # SET_RF/SET_STREAM are controller-side staging operations and
                 # should answer promptly; START has its own caller-side budget.
                 interval=.5, retries=12):
        self.sock, self.peer, self.ids = sock, peer, ids
        self.pump, self.uncertain = pump, uncertain
        self.interval, self.retries = interval, retries
        self.boot = 0
        self.counts = Counter()
        self.capture_floor = 0

    def discover_ku5p(self) -> RxInfo:
        """RX-only v1 discovery; only validated status 10/11 may rebase IDs."""
        for _ in range(4):
            response = self._exchange(6, discover=True, allowed_errors=(10, 11))
            info = RxInfo.unpack(response.payload)
            # Errors 10/11 also carry valid highs; persist before the new request.
            for name, high in (("request", info.rx_request_high), ("config", info.config_high),
                               ("capture", info.capture_high)):
                self.ids.advance(name, high)
            if response.status == 0:
                if info.rx_request_high < response.request_id:
                    raise ControlError("RX INFO successful high-water predates its request")
                caps = info.capabilities
                legacy_sim = (caps >> 16) == 0 and (caps & 0xffff) == 3
                if not legacy_sim and (info.schema, info.adc_sample_rate_hz,
                                        caps >> 16, caps & 0xffff) != (1, 25_000_000, 23, 0x001f):
                    raise ControlError(
                        f"Unsupported KU5P RX info: schema={info.schema} adc={info.adc_sample_rate_hz} "
                        f"firmware={caps >> 16} features={caps & 0xffff:#06x} (expect 1/25000000/23/0x001f)")
                self.boot = response.boot_id
                self.capture_floor = info.capture_high
                return info
        raise ControlError("RX request ID synchronization failed")

    def _exchange(self, opcode: int, config=0, payload=b"", *, discover=False,
                  allowed_errors=()) -> ControlMessage:
        request_id = self.ids.reserve("request")
        boot = 0 if discover else self.boot
        if not discover and not boot:
            raise ControlError("Discover boot before issuing commands")
        request = ControlMessage(0, request_id, config, opcode, 0, boot, payload)
        validate_request(request)  # Network transport only permits RFCT v1 RX 1..6.
        wire = request.pack()
        for attempt in range(self.retries + 1):
            self.sock.sendto(wire, self.peer)
            self.counts["requests_sent"] += 1
            deadline = time.monotonic() + self.interval
            while time.monotonic() < deadline:
                self.pump()
                ready, _, _ = select.select([self.sock], [], [], min(.01, max(0, deadline-time.monotonic())))
                if not ready:
                    continue
                packet, source = self.sock.recvfrom(65535)
                if source != self.peer:
                    self.counts["wrong_peer"] += 1
                    continue
                try:
                    response = decode_control(packet)
                except ProtocolError:
                    self.counts["invalid_response"] += 1
                    continue
                if (response.kind, response.request_id, response.opcode, response.config_id) != (1, request_id, opcode, config):
                    self.counts["wrong_echo"] += 1
                    continue
                if response.status == 9 or (not discover and response.boot_id != boot):
                    self.boot = 0
                    self.ids.disown()
                    self.uncertain()
                    raise BootChanged("KU5P boot changed; capture revoked, rediscovery required")
                if response.status and response.status not in allowed_errors:
                    self.uncertain()
                    raise ControlError(f"RFCT {opcode}: {STATUSES[response.status]}")
                return response
            self.uncertain()
            self.counts["response_timeouts"] += 1
        raise ControlTimeout(f"RFCT opcode {opcode}: result unknown after identical retries")

    def request(self, opcode: int, config=0, payload=b"", *, discover=False) -> Snapshot:
        if opcode not in (1, 2, 3, 4, 5):
            raise ControlError("Snapshot request accepts RX opcodes 1..5 only")
        for _ in range(8):
            response = self._exchange(opcode, config, payload, discover=discover,
                                      allowed_errors=(6,) if opcode == 5 else ())
            if response.status != 6:
                break
            # A completed BUSY read may be cached; use a NEW read ID. Transport
            # timeout retries inside _exchange still resend identical bytes.
            self.counts["busy_status_reads"] += 1
            time.sleep(min(self.interval, .1))
        else:
            self.uncertain()
            raise ControlError("GET_STATUS persistently BUSY; RX status unavailable")
        if discover:
            self.boot = response.boot_id
        return Snapshot.unpack(response.payload)

    def stop_owned(self) -> Snapshot:
        """Fresh check narrows takeover races; protocol has no atomic lease/STOP guard."""
        current = self.request(5)
        owner = self.ids.ownership()
        if current.state == 0:
            # Even IDLE metadata can show a later external capture.
            if owner and owner[0] == self.boot and current.capture_id not in (0, owner[2]):
                self.ids.disown()
                raise SessionConflict("External capture replaced owned session; no STOP sent")
            self.ids.disown()
            return current
        if owner != (self.boot, current.active_config_id, current.capture_id):
            self.ids.disown()
            self.uncertain()
            raise SessionConflict("External RX session; no STOP sent")
        idle = self.request(4)
        if idle.state != 0 or idle.capture_id != current.capture_id or idle.active_config_id != current.active_config_id:
            self.uncertain()
            raise ControlError("Owned STOP did not confirm same capture IDLE")
        self.ids.disown()
        return idle



def check_running(snapshot: Snapshot, rf, stream, config: int, capture: int):
    expected = dict(state=2, active_config_id=config, capture_id=capture,
        source=stream.source, mode=stream.mode, rx_channel=rf.rx_channel,
        stream_id=stream.stream_id, lo_hz=rf.lo_hz,
        adc_sample_rate_hz=rf.adc_sample_rate_hz, fs_eff_hz=stream.fs_eff_hz,
        rx_bandwidth_hz=rf.rx_bandwidth_hz, baseband_center_hz=stream.baseband_center_hz,
        rx_gain_mdB=rf.rx_gain_mdB, decimation=stream.decimation,
        hop_points=stream.hop_points, window_points=stream.window_points)
    required_flags = 6 if stream.source == 1 else 5
    if snapshot.status_flags & ~0x1f or snapshot.status_flags & required_flags != required_flags or any(getattr(snapshot, k) != v for k, v in expected.items()):
        raise ControlError("START/status snapshot disagrees with requested capture or actual configuration")
    if rf.gain_mode in (1, 2) and snapshot.rx_gain_mdB != -2147483648:
        raise ControlError("HW20 AGC snapshot must report INT32_MIN gain sentinel")
