"""Backends, classification acceptance and display-height conversion."""
from __future__ import annotations
import math
from collections import deque
from pathlib import Path
import socket
import struct
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "reference"))
from fft_q15_reference import power_spectrum

HEADER = struct.Struct("<4s7I")


class ReferenceBackend:
    """Real CPU integer FFT; no classifier and no hardware display."""
    def process(self, capture, seq, raw, window):
        started = time.perf_counter_ns()
        power = power_spectrum(list(struct.iter_unpack("<hh", raw)), window)
        return power, None, {"cpu_fft_us": (time.perf_counter_ns()-started)//1000}

    def display(self, *args):
        return False

    def close(self):
        pass


class NativeBackend:
    """Persistent native worker over loopback. SDK stdout never carries RPC data."""
    def __init__(self, port, timeout=30, logit_count=18):
        if logit_count <= 0:
            raise ValueError("logit_count must be positive")
        self.dashboard = None
        self.logit_count = logit_count
        self.sock = socket.create_connection(("127.0.0.1", port), timeout=timeout)
        self.sock.settimeout(timeout)
        self.mode = self.rpc(0, 0, 0, 0, b"").decode("ascii")
        if self.mode not in ("host-cpu", "zg330-pl"):
            raise RuntimeError("Unknown worker capability")

    def read_exact(self, length):
        result = bytearray()
        while len(result) < length:
            part = self.sock.recv(length-len(result))
            if not part:
                raise RuntimeError("Native worker disconnected")
            result.extend(part)
        return bytes(result)

    def rpc(self, opcode, capture, seq, argument, payload):
        self.sock.sendall(HEADER.pack(b"RFWK", 1, opcode, capture, seq, argument, 0, len(payload))+payload)
        header = HEADER.unpack(self.read_exact(32))
        if header[:6] != (b"RFRS", 1, opcode, capture, seq, argument) or header[7] > 8192:
            raise RuntimeError("Native response identity/length mismatch")
        body = self.read_exact(header[7])
        if header[6]:
            raise RuntimeError(body.decode("utf-8", errors="replace"))
        return body

    def process(self, capture, seq, raw, window):
        body = self.rpc(1, capture, seq, int(window == "hann"), raw)
        result_size = 4096 + self.logit_count * 4 + 24
        time_offset = 4096 + self.logit_count * 4
        if len(body) != result_size:
            raise RuntimeError("Wrong native result size")
        power = list(struct.unpack_from("<1024I", body))
        logits = list(struct.unpack_from("<%df" % self.logit_count, body, 4096))
        fft_us, npu_us, total_us = struct.unpack_from("<3Q", body, time_offset)
        if not all(math.isfinite(x) for x in logits):
            raise RuntimeError("Nonfinite model output")
        return power, logits, {"fft_us": fft_us, "inference_us": npu_us, "native_total_us": total_us}

    def display(self, capture, seq, heights, class_id, confidence, flags, peak):
        if self.dashboard and not self.dashboard.stage(class_id):
            return False
        body = self.rpc(2, capture, seq, class_id,
            struct.pack("<1024H4I", *heights, confidence, flags, peak, 0))
        if body not in (b"\0\0\0\0", b"\1\0\0\0"):
            raise RuntimeError("Bad display acknowledgement")
        return body == b"\1\0\0\0"

    def close(self):
        if self.dashboard: self.dashboard.close()
        self.sock.close()


class ClassDecision:
    def __init__(self, labels, threshold=None, stable_windows=3):
        if not labels or not 1 <= stable_windows <= 1024:
            raise ValueError("Labels and positive stability window required")
        if threshold is not None and (not math.isfinite(threshold) or not 0 <= threshold <= 1):
            raise ValueError("confidence threshold must be null or in [0,1]")
        self.labels, self.threshold, self.required = labels, threshold, stable_windows
        self.history = deque(maxlen=64)
        self.previous = None
        self.streak = 0

    def reset(self):
        self.history.clear()
        self.previous = None
        self.streak = 0

    def evaluate(self, logits, gap=False):
        if gap:
            self.previous = None
            self.streak = 0
        if logits is None:
            return dict(candidate=None, label="UNKNOWN", class_id=255, confidence=0., reason="classifier_unavailable")
        if len(logits) != len(self.labels) or not all(math.isfinite(v) for v in logits):
            raise ValueError("Logit count does not match labels")
        index = max(range(len(logits)), key=logits.__getitem__)
        exps = [math.exp(x-max(logits)) for x in logits]
        confidence = exps[index]/sum(exps)
        if self.threshold is None:
            probabilities = [v/sum(exps) for v in exps]
            self.history.append(probabilities)
            chosen = sorted(self.history, key=max, reverse=True)[:16]
            means = [sum(row[i] for row in chosen)/len(chosen) for i in range(len(self.labels))]
            winner = max(range(len(means)), key=means.__getitem__)
            ready = len(chosen) == 16
            return dict(candidate=self.labels[winner], label=self.labels[winner],
                        class_id=winner, confidence=means[winner],
                        reason='top16_mean' if ready else 'collecting_top16',
                        aggregation_frames=len(chosen), history_frames=len(self.history),
                        top_candidates=[dict(label=self.labels[i], probability=means[i]) for i in sorted(range(len(means)), key=means.__getitem__, reverse=True)[:3]])
        self.streak = self.streak+1 if self.previous == index else 1
        self.previous = index
        reason = ("threshold_uncalibrated" if self.threshold is None else
                  "below_threshold" if confidence < self.threshold else
                  "unstable" if self.streak < self.required else "accepted")
        accepted = reason == "accepted"
        return dict(candidate=self.labels[index], label=self.labels[index] if accepted else "UNKNOWN",
                    class_id=index if accepted else 255, confidence=confidence, reason=reason)


def display_heights(power):
    if len(power) != 1024 or any(not 0 <= p <= 0x80000000 for p in power):
        raise ValueError("Invalid uint32 FFT power")
    logs = [10*math.log10(max(p, 1)) for p in power]
    ceiling = max(max(logs), 60.)
    # 60 dB relative display range, peak held at 400. Zero stays at zero.
    values = [0 if not p else round(max(0., min(1., (v-ceiling+60)/60))*400)
              for p, v in zip(power, logs)]
    return values[512:]+values[:512]
