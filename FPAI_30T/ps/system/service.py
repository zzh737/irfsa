"""Wujing PS service: RFCT acquisition -> bounded IQ -> PL/NPU -> coherent HDMI.

No board configuration or tool installation is performed by this program.
Reference mode is explicitly CPU FFT only; native-host is actual iCraft CPU.
"""
from __future__ import annotations
import argparse
from collections import Counter, deque
from dataclasses import asdict
import hashlib
import json
import math
from pathlib import Path
import queue
import select
import signal
import socket
import struct
import sys
import threading
import time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "ps/udp"))
from rf_protocol import RFConfig, StreamConfig, validate_configuration
from udp_iq_receiver import ReceiverConfig, UdpIQReceiver
from control import ControlClient, ControlError, ControlTimeout, SessionConflict, IdStore, check_running
from processing import ClassDecision, NativeBackend, ReferenceBackend, display_heights


class SystemService:
    def __init__(self, config, output: Path, ids: IdStore, backend):
        self.config, self.output, self.ids, self.backend = config, output, ids, backend
        self.rf = RFConfig(**config["rf"])
        self.stream = StreamConfig(**config["stream"])
        validate_configuration(self.rf, self.stream)
        ReceiverConfig(1, config["bind"], config["iq_port"], config["peer"], config["peer_iq_port"],
                       self.rf.lo_hz, self.stream.fs_eff_hz, self.stream.baseband_center_hz,
                       self.rf.rx_gain_mdB, config["queue_depth"])
        for key in ("control_local_port", "control_peer_port"):
            if not 0 <= config[key] <= 65535 or (key == "control_peer_port" and config[key] == 0):
                raise ValueError(f"Invalid {key}")
        if config.get("ku5p_v2"):
            raise ValueError("Obsolete UDP TX discovery config; use rx_info=true")
        if config.get("rx_info", False):
            if not (300_000_000 <= self.rf.lo_hz <= 6_000_000_000 and
                    self.rf.adc_sample_rate_hz == 25_000_000 and
                    self.rf.rx_bandwidth_hz == 500_000 and self.rf.rx_gain_mdB == 20_000 and
                    self.stream.source == self.stream.mode == self.stream.baseband_center_hz == 0 and
                    (self.stream.fs_eff_hz, self.stream.decimation) in ((1_000_000,25),(25_000_000,1))):
                raise ValueError("Configuration exceeds current KU5P RX capabilities")
        elif not config.get("allow_legacy_status_discovery", False):
            raise ValueError("rx_info required unless legacy GET_STATUS discovery explicitly allowed")
        for key, default in (("result_max_age_s", .5), ("display_stale_s", 1.), ("network_timeout_s", 3.)):
            value = config.get(key, default)
            if not math.isfinite(value) or value <= 0:
                raise ValueError(f"Invalid {key}")
        self.decision = ClassDecision(config["labels"], config["confidence_threshold"], config["stable_windows"])
        if not 1 <= config["queue_depth"] <= 256:
            raise ValueError("queue_depth must be 1..256")
        if config["window"] not in ("hann", "rectangular"):
            raise ValueError("Invalid FFT window")
        self.counts = Counter()
        self.gate = threading.Lock()
        self.route = threading.Lock()
        self.active = False
        self.stopping = threading.Event()
        self.work_errors = []
        self.display_status = {}
        self.early = deque(maxlen=1024)
        self.invalidate_display = threading.Event()
        self.last_iq = time.monotonic()
        self.capture = self.config_id = 0
        self.receiver = None
        self.output.mkdir(parents=True, exist_ok=False)

    def revoke(self):
        with self.gate:
            self.active = False
        self.invalidate_display.set()

    def run(self, *, windows=16, duration=10., replay_capture=None, ready=None):
        if (windows is not None and windows < 1) or (duration is not None and (not math.isfinite(duration) or duration <= 0)):
            raise ValueError("windows/duration must be positive")
        limit = windows if windows is not None else float("inf")
        cfg = self.config
        started = time.monotonic()
        error = None
        stop_error = None
        client = worker = network = None
        network_stop = threading.Event()
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as iq_sock, \
             socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as control_sock, \
             (self.output/"results.jsonl").open("x", encoding="utf-8") as records, \
             (self.output/"power.u32le").open("xb") as powers, \
             (self.output/"input.iq").open("xb") as inputs:
            # Bind data socket BEFORE RFCT START, including the START retry period.
            iq_sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 4*1024*1024)
            iq_sock.bind((cfg["bind"], cfg["iq_port"]))
            iq_sock.setblocking(False)
            control_sock.bind((cfg["bind"], cfg["control_local_port"]))
            control_sock.setblocking(False)
            peer = (cfg["peer"], cfg["peer_iq_port"])
            def receive():
                # Dedicated receiver stays live through RFCT retries and slow PL/NPU/RPC.
                try:
                    while not network_stop.is_set():
                        ready_iq, _, _ = select.select([iq_sock], [], [], .01)
                        if ready_iq:
                            for _ in range(256):
                                try:
                                    packet, address = iq_sock.recvfrom(65535)
                                except BlockingIOError:
                                    break
                                now = time.monotonic()
                                if address != peer:
                                    self.counts["wrong_peer"] += 1
                                    continue
                                with self.route:
                                    if self.receiver is None:
                                        if len(self.early) == self.early.maxlen:
                                            self.counts["early_datagrams_dropped"] += 1
                                        self.early.append((packet, address, now))
                                    elif self.active:
                                        before = self.receiver.reassembler.counts["complete"]
                                        self.receiver.accept_datagram(packet, address, now)
                                        if self.receiver.reassembler.counts["complete"] > before:
                                            self.last_iq = now
                                    else:
                                        self.counts["revoked_datagrams"] += 1
                        with self.route:
                            if self.receiver:
                                self.receiver.reassembler.expire()
                except Exception as exc:
                    self.work_errors.append(exc)
                    self.revoke()
                    self.stopping.set()

            network = threading.Thread(target=receive, name="iq-network")
            network.start()

            def consume():
                previous = -1
                offset = 0
                displayed = time.monotonic()
                invalidated = False
                while not self.stopping.is_set() or self.invalidate_display.is_set():
                    if self.invalidate_display.is_set() or (not invalidated and time.monotonic()-displayed > cfg.get("display_stale_s", 1.)):
                        self.invalidate_display.clear()
                        self.decision.reset()
                        try:
                            submitted = self.backend.display(self.capture, max(previous, 0), [0]*1024, 255, 0, 2, 0)
                            self.counts["display_invalidations"] += int(submitted)
                        except Exception as exc:
                            self.work_errors.append(exc)
                            self.revoke()
                            self.invalidate_display.clear()
                            self.stopping.set()
                            break
                        invalidated = True
                    if self.stopping.is_set():
                        break
                    try:
                        window = self.receiver.inbox.get(timeout=.05)
                    except queue.Empty:
                        continue
                    try:
                        if not self.active:
                            self.counts["revoked_windows"] += 1
                            continue
                        h = window.header
                        if time.monotonic()-window.received_at > cfg.get("result_max_age_s", .5):
                            self.counts["stale_processing_windows"] += 1
                            continue
                        tick = time.perf_counter_ns()
                        power, logits, timing = self.backend.process(h.capture_id, h.window_seq, window.payload, cfg["window"])
                        heights = display_heights(power)
                        gap = h.window_seq != previous+1 or bool(h.flags & 1)
                        with self.gate:
                            if not self.active or self.counts["published"] >= limit:
                                self.counts["revoked_results"] += 1
                                continue
                            if time.monotonic()-window.received_at > cfg.get("result_max_age_s", .5):
                                self.counts["stale_processing_results"] += 1
                                continue
                            decision = self.decision.evaluate(logits, gap)
                            # Exact digital zero is unambiguously no signal. No uncalibrated
                            # nonzero energy threshold or model-input transform is introduced.
                            if not any(window.payload):
                                self.decision.reset()
                                decision.update(label="UNKNOWN", class_id=255, reason="zero_iq")
                            peak = max(range(1024), key=power.__getitem__)
                            bin_hz = (peak if peak < 512 else peak-1024)*h.fs_eff_hz/1024
                            flags = int(gap) | (int(decision["class_id"] == 255) << 1)
                            # Release publication lock during device RPC; network has its own routing lock.
                        if getattr(self.backend, "dashboard", None):
                            self.backend.dashboard.state = dict(rf=cfg["rf"], fs=h.fs_eff_hz, lo=h.lo_hz,
                                decision=decision, timing=timing, peak=peak,
                                age_ms=(time.monotonic()-window.received_at)*1000,
                                gaps=self.counts["delivery_gap_events"]+int(gap), status=self.display_status)
                        self.counts["delivery_gap_events"] += int(gap)
                        display_submitted = self.backend.display(h.capture_id, h.window_seq, heights, decision["class_id"],
                                             round(decision["confidence"]*1000), flags, peak)
                        with self.gate:
                            if not self.active:
                                self.counts["revoked_results"] += 1
                                self.invalidate_display.set()
                                continue
                            displayed = time.monotonic()
                            invalidated = False
                            packed_power = struct.pack("<1024I", *power)
                            record = dict(identity={"boot_id": getattr(client, "boot", 0),
                                "config_id": self.config_id, "capture_id": h.capture_id, "window_seq": h.window_seq},
                                iq_header=asdict(h), delivery_gap=gap, window=cfg["window"],
                                backend=cfg["backend"], source=self.stream.source, display_submitted=display_submitted,
                                decision=decision, logits=logits, peak_bin=peak,
                                peak_rf_hz=h.lo_hz+h.baseband_center_hz+bin_hz,
                                timings_us={**timing, "process_and_display_us": (time.perf_counter_ns()-tick)//1000},
                                byte_offset=offset, byte_count=4096,
                                iq_sha256=hashlib.sha256(window.payload).hexdigest(),
                                power_sha256=hashlib.sha256(packed_power).hexdigest())
                            inputs.write(window.payload);powers.write(packed_power)
                            records.write(json.dumps(record, allow_nan=False)+"\n");records.flush()
                            offset += 4096
                            previous = h.window_seq
                            self.counts["published"] += 1
                    except Exception as exc:
                        self.work_errors.append(exc)
                        self.revoke()
                        self.stopping.set()
                    finally:
                        self.receiver.inbox.task_done()

            try:
                snapshot = None
                if replay_capture is None:
                    client = ControlClient(control_sock, (cfg["peer"], cfg["control_peer_port"]),
                                           self.ids, uncertain=self.revoke,
                                           interval=cfg.get("control_retry_s", .5), retries=cfg.get("control_retries", 12))
                    if cfg.get("rx_info", False):
                        client.discover_ku5p()
                        snapshot = client.request(5)  # Fresh ID, never use cached discovery as IDLE.
                    else:
                        snapshot = client.request(5, discover=True)
                    if snapshot.state != 0:
                        if self.ids.ownership() == (client.boot, snapshot.active_config_id, snapshot.capture_id):
                            snapshot = client.stop_owned()
                        else:
                            self.ids.disown()
                            raise SessionConflict("RX busy/error without matching owned capture; no takeover")
                    self.config_id = self.ids.reserve("config", snapshot.active_config_id)
                    self.capture = self.ids.reserve("capture", max(snapshot.capture_id, client.capture_floor))
                    client.request(1, self.config_id, self.rf.pack())
                    client.request(2, self.config_id, self.stream.pack())
                    # Exclude data preceding START, while retaining early data arriving with its ACK.
                    with self.route:
                        self.early.clear()
                    self.ids.own(client.boot, self.config_id, self.capture)
                    snapshot = client.request(3, self.config_id, struct.pack(">I", self.capture))
                    check_running(snapshot, self.rf, self.stream, self.config_id, self.capture)
                else:
                    self.capture = replay_capture
                self.receiver = UdpIQReceiver(ReceiverConfig(self.capture, cfg["bind"], cfg["iq_port"],
                    cfg["peer"], cfg["peer_iq_port"], self.rf.lo_hz, self.stream.fs_eff_hz,
                    self.stream.baseband_center_hz, self.rf.rx_gain_mdB, cfg["queue_depth"]))
                self.display_status = asdict(snapshot) if snapshot else {}
                session = dict(config=cfg, mode="RFCT-acknowledged" if client else "explicit-replay-no-RFCT",
                    boot_id=getattr(client, "boot", 0), capture_id=self.capture, config_id=self.config_id,
                    snapshot=asdict(snapshot) if snapshot else None,
                    socket_rcvbuf=iq_sock.getsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF))
                (self.output/"session.json").write_text(json.dumps(session, indent=2), encoding="utf-8")
                with self.route:
                    self.active = True
                    self.last_iq = time.monotonic()
                    while self.early:
                        packet, address, arrival = self.early.popleft()
                        if time.monotonic()-arrival < .1:
                            self.receiver.accept_datagram(packet, address, arrival)
                        else:
                            self.counts["early_expired"] += 1
                worker = threading.Thread(target=consume, name="pl-npu-display")
                worker.start()
                if ready:
                    ready(iq_sock.getsockname(), self.capture)
                deadline = time.monotonic()+duration if duration is not None else float("inf")
                next_status = time.monotonic()+cfg.get("status_interval_s", 1.)
                while self.counts["published"] < limit and time.monotonic() < deadline and not self.stopping.is_set():
                    if self.work_errors:
                        raise RuntimeError("Processing worker failed") from self.work_errors[0]
                    self.stopping.wait(.01)
                    if time.monotonic()-self.last_iq > cfg.get("network_timeout_s", 3.):
                        raise ControlTimeout("No complete valid IQ windows; network/capture fault")
                    if client and time.monotonic() >= next_status:
                        current = client.request(5)
                        if (current.capture_id, current.active_config_id) != (self.capture, self.config_id):
                            self.ids.disown()
                            raise SessionConflict("Owned RX session lost; external capture must not be stopped")
                        check_running(current, self.rf, self.stream, self.config_id, self.capture)
                        self.display_status = asdict(current)
                        with self.gate:
                            self.active = True
                        next_status = time.monotonic()+cfg.get("status_interval_s", 1.)
                if self.work_errors:
                    raise RuntimeError("Processing worker failed") from self.work_errors[0]
            except BaseException as exc:
                error = exc
            finally:
                # No more results/display are admitted once STOP begins.
                self.revoke()
                self.stopping.set()
                if client and client.boot and self.ids.ownership():
                    try:
                        client.stop_owned()
                    except Exception as exc:
                        stop_error = repr(exc)
                if worker:
                    worker.join()  # backend has a finite socket timeout; final UNKNOWN clears old display
                else:
                    try:
                        self.backend.display(self.capture, 0, [0]*1024, 255, 0, 2, 0)
                    except Exception as exc:
                        self.counts["display_invalidation_failures"] += 1
                        if error is None:
                            error = exc
                network_stop.set()
                if network:
                    network.join()
                report = dict(counts=dict(self.counts), target_reached=self.counts["published"] >= limit,
                    elapsed_s=time.monotonic()-started, stop_error=stop_error,
                    error=repr(error) if error else None,
                    receiver=self.receiver.stats() if self.receiver else None,
                    control=dict(client.counts) if client else None)
                (self.output/"summary.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
        if error:
            raise error
        if stop_error:
            raise ControlError(f"STOP outcome unknown: {stop_error}")
        return report


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--config", type=Path, default=ROOT/"config/system_ku5p.json")
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--state", type=Path, default=ROOT/"run/controller.sqlite")
    p.add_argument("--windows", type=int, default=16)
    p.add_argument("--duration", type=float, default=10.)
    p.add_argument("--continuous", action="store_true", help="run until interrupted; output grows on disk")
    p.add_argument("--backend", choices=["reference", "native-host", "native-board"])
    p.add_argument("--replay-only", action="store_true")
    p.add_argument("--capture", type=int)
    p.add_argument("--recoveries", type=int, default=2, help="bounded RFCT rediscovery/reconfiguration attempts")
    args = p.parse_args()
    if args.replay_only != (args.capture is not None):
        p.error("--replay-only and --capture must be supplied together")
    if args.recoveries < 0:
        p.error("recoveries must be nonnegative")
    def interrupted(*_):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, interrupted)
    if hasattr(signal, "SIGBREAK"):
        signal.signal(signal.SIGBREAK, interrupted)
    backend = ids = None
    try:
        cfg = json.loads(args.config.read_text(encoding="utf-8"))
        labels = json.loads((ROOT/cfg.get("labels_file", "npu/labels.json")).read_text(encoding="utf-8"))["classes"]
        if cfg["labels"] != labels:
            raise ValueError("Label order differs from the frozen model manifest")
        if args.backend:
            cfg["backend"] = args.backend
        if cfg["backend"] == "reference":
            backend = ReferenceBackend()
        else:
            backend = NativeBackend(cfg["worker_port"], logit_count=len(cfg["labels"]))
            expected = {"native-host": "host-cpu", "native-board": "zg330-pl"}[cfg["backend"]]
            if backend.mode != expected:
                raise RuntimeError(f"Expected {expected} worker; got {backend.mode}")
        if cfg.get("dashboard", False) and cfg["backend"] == "native-board":
            from dashboard import Dashboard
            backend.dashboard = Dashboard()
        ids = IdStore(args.state)
        for attempt in range(args.recoveries+1):
            output = args.output if attempt == 0 else args.output.with_name(args.output.name+f"_recovery_{attempt}")
            service = SystemService(cfg, output, ids, backend)
            try:
                report = service.run(windows=None if args.continuous else args.windows, duration=None if args.continuous else args.duration,
                    replay_capture=args.capture if args.replay_only else None,
                    ready=lambda address, capture: print(json.dumps({"listening": address, "capture": capture,
                                                                     "backend": cfg["backend"]}), flush=True))
                break
            except ControlError as exc:
                if isinstance(exc, SessionConflict) or args.replay_only or attempt == args.recoveries:
                    raise
                print(f"RFCT recovery {attempt+1}: {exc}; revoke old capture, rediscover and reserve new IDs", file=sys.stderr)
        print(json.dumps(report), flush=True)
        return 0 if report["target_reached"] else 2
    except KeyboardInterrupt:
        return 130
    except Exception as exc:
        print(f"{type(exc).__name__}: {exc}", file=sys.stderr)
        return 1
    finally:
        if backend:
            backend.close()
        if ids:
            ids.close()


if __name__ == "__main__":
    raise SystemExit(main())
