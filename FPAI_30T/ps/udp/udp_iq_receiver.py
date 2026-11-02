"""Bounded RFIQ replay receiver for PS Linux or PC. Standard-library only.

This is explicitly a replay diagnostic, not the RFCT-controlled acquisition
service. Production must bind before START and gate publication on its ACK.
"""
from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import asdict, dataclass
import hashlib
import ipaddress
import json
import math
from pathlib import Path
import queue
import socket
import threading
import time
from typing import Callable

from rf_protocol import IQReassembler, IQWindow, ProtocolError


@dataclass(frozen=True)
class ReceiverConfig:
    capture_id: int
    bind: str = "192.168.10.1"
    port: int = 40000
    peer: str = "192.168.10.2"
    peer_port: int = 40000
    lo_hz: int = 100_000_000
    fs_eff_hz: int = 1_000_000
    baseband_center_hz: int = 0
    rx_gain_mdB: int = 10_000
    queue_depth: int = 8

    def __post_init__(self) -> None:
        ipaddress.IPv4Address(self.bind)
        peer = ipaddress.IPv4Address(self.peer)
        if peer.is_unspecified or peer.is_multicast or int(peer) == 0xffffffff:
            raise ValueError("peer must be a specific unicast IPv4 address")
        if not 1 <= self.capture_id <= 0xffffffff:
            raise ValueError("capture_id must be a nonzero u32")
        if not (0 <= self.port <= 65535 and 1 <= self.peer_port <= 65535):
            raise ValueError("invalid UDP port")
        if not 1 <= self.lo_hz <= 0xffffffffffffffff or not 1 <= self.fs_eff_hz <= 0xffffffff:
            raise ValueError("invalid LO/sample rate")
        if not -(2**31) <= self.baseband_center_hz < 2**31 or not -(2**31) <= self.rx_gain_mdB < 2**31:
            raise ValueError("offset/gain must fit signed int32")
        if not 1 <= self.queue_depth <= 256:
            raise ValueError("queue_depth must be 1..256")


@dataclass(frozen=True)
class DeliveredWindow:
    window: IQWindow
    delivery_gap: bool


class UdpIQReceiver:
    """One replay capture per instance; callback runs on a bounded worker queue.

    on_window must return in bounded time. Exceptions terminate the run and
    propagate to the caller. No PL/NPU SDK or network configuration is invoked.
    """
    def __init__(self, config: ReceiverConfig):
        self.config = config
        self.counts: Counter = Counter()
        self.reassembler = IQReassembler(config.capture_id, expected={
            "stream_id": 1, "lo_hz": config.lo_hz,
            "fs_eff_hz": config.fs_eff_hz,
            "baseband_center_hz": config.baseband_center_hz,
            "rx_gain_mdB": config.rx_gain_mdB,
        })
        self.inbox: queue.Queue[IQWindow] = queue.Queue(config.queue_depth)
        self._used = False

    def stats(self) -> dict:
        return {"socket_and_delivery": dict(self.counts),
                "reassembly": dict(self.reassembler.counts),
                "pending_windows": len(self.reassembler.pending)}

    def accept_datagram(self, packet: bytes, address: tuple[str, int],
                        now: float | None = None) -> bool:
        self.counts["datagrams"] += 1
        if address != (self.config.peer, self.config.peer_port):
            self.counts["wrong_peer"] += 1
            return False
        try:
            window = self.reassembler.feed(packet, now)
        except ProtocolError:
            self.counts["invalid_datagrams"] += 1
            return False
        if window is None:
            return False
        try:
            self.inbox.put_nowait(window)
        except queue.Full:
            self.counts["consumer_drop_windows"] += 1
            return False
        self.counts["queued_windows"] += 1
        return True

    def run(self, on_window: Callable[[DeliveredWindow], None], *,
            max_windows: int = 16, duration: float = 10.0,
            on_ready: Callable[[tuple[str, int]], None] | None = None) -> dict:
        if self._used:
            raise RuntimeError("Use a new receiver for every capture/run")
        if max_windows < 1 or not math.isfinite(duration) or duration <= 0:
            raise ValueError("max_windows and duration must be positive")
        self._used = True
        stop = threading.Event()
        worker_errors: list[Exception] = []

        def consume() -> None:
            previous = -1
            while not stop.is_set() or not self.inbox.empty():
                try:
                    window = self.inbox.get(timeout=.05)
                except queue.Empty:
                    continue
                try:
                    seq = window.header.window_seq
                    gap = seq != previous + 1 or bool(window.header.flags & 1)
                    on_window(DeliveredWindow(window, gap))
                    previous = seq
                    self.counts["delivered_windows"] += 1
                    if gap:
                        self.counts["delivery_gaps"] += 1
                except Exception as exc:
                    worker_errors.append(exc)
                    stop.set()
                    return
                finally:
                    self.inbox.task_done()

        worker = threading.Thread(target=consume, name="iq-consumer")
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 4 * 1024 * 1024)
            sock.bind((self.config.bind, self.config.port))
            sock.settimeout(.05)
            self.counts["socket_rcvbuf_bytes"] = sock.getsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF)
            worker.start()
            try:
                if on_ready:
                    on_ready(sock.getsockname())
                deadline = time.monotonic() + duration
                while self.counts["queued_windows"] < max_windows and not stop.is_set():
                    now = time.monotonic()
                    if now >= deadline:
                        break
                    try:
                        packet, address = sock.recvfrom(65535)
                    except socket.timeout:
                        self.reassembler.expire()
                        continue
                    self.accept_datagram(packet, address)
                self.reassembler.expire()
            finally:
                stop.set()
                worker.join()
        if worker_errors:
            raise RuntimeError("IQ consumer failed") from worker_errors[0]
        result = self.stats()
        result["target_reached"] = self.counts["delivered_windows"] == max_windows
        return result


class CaptureSink:
    """Streaming raw + metadata capture. Directory must be new; files never overwrite."""
    def __init__(self, output: Path | None, config: ReceiverConfig):
        self.raw = self.metadata = None
        self.offset = 0
        if output is not None:
            output.mkdir(parents=True, exist_ok=False)
            (output / "session.json").write_text(json.dumps({
                "mode": "replay-diagnostic-no-RFCT", "config": asdict(config),
                "format": "int16 little-endian interleaved I,Q, 1024 complex/window",
            }, indent=2), encoding="utf-8")
            self.raw = (output / "windows.iq").open("xb")
            self.metadata = (output / "windows.jsonl").open("x", encoding="utf-8")

    def __call__(self, frame: DeliveredWindow) -> None:
        if self.raw is None:
            return
        # Integration boundary: frame.window.payload is one complete 4096-byte IQ
        # frame. Use the real SDK adapter here later; do not fabricate inference.
        payload = frame.window.payload
        self.raw.write(payload)
        record = {**asdict(frame.window.header), "delivery_gap": frame.delivery_gap,
                  "byte_offset": self.offset, "byte_count": len(payload),
                  "sha256": hashlib.sha256(payload).hexdigest()}
        self.metadata.write(json.dumps(record) + "\n")
        self.offset += len(payload)

    def close(self) -> None:
        for stream in (self.raw, self.metadata):
            if stream is not None:
                stream.close()


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--replay-only", action="store_true", required=True,
                   help="explicitly acknowledge that this tool does not perform RFCT START")
    p.add_argument("--capture", type=int, required=True)
    p.add_argument("--bind", default="192.168.10.1")
    p.add_argument("--port", type=int, default=40000)
    p.add_argument("--peer", default="192.168.10.2")
    p.add_argument("--peer-port", type=int, default=40000)
    p.add_argument("--lo", type=int, default=100_000_000)
    p.add_argument("--fs", type=int, default=1_000_000)
    p.add_argument("--center", type=int, default=0)
    p.add_argument("--gain-mdb", type=int, default=10_000)
    p.add_argument("--queue-depth", type=int, default=8)
    p.add_argument("--windows", type=int, default=16)
    p.add_argument("--duration", type=float, default=10)
    p.add_argument("--output-dir", type=Path)
    a = p.parse_args()
    if a.windows < 1 or not math.isfinite(a.duration) or a.duration <= 0:
        p.error("--windows and --duration must be positive")
    sink = None
    try:
        config = ReceiverConfig(a.capture, a.bind, a.port, a.peer, a.peer_port,
                                a.lo, a.fs, a.center, a.gain_mdb, a.queue_depth)
        receiver = UdpIQReceiver(config)
        sink = CaptureSink(a.output_dir, config)
        result = receiver.run(sink, max_windows=a.windows, duration=a.duration,
            on_ready=lambda address: print(json.dumps({"listening": address,
                "capture": a.capture, "mode": "replay-only"}), flush=True))
        print(json.dumps(result), flush=True)
        return 0 if result["target_reached"] else 2
    except (ValueError, OSError, RuntimeError) as exc:
        p.exit(1, f"{exc}\n")
    except KeyboardInterrupt:
        return 130
    finally:
        if sink is not None:
            sink.close()


if __name__ == "__main__":
    raise SystemExit(main())
