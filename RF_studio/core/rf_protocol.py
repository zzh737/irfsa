"""RFIQ/RFCT v1 wire reference. Standard library only; no hardware control."""
from __future__ import annotations

from collections import Counter
from dataclasses import asdict, dataclass
import struct
import time
import zlib

DATA_HEADER = struct.Struct(">4sBBHIIIHHQQIiHHiII")
CONTROL_HEADER = struct.Struct(">4sBBHIIHHIII")
RF_BODY = struct.Struct(">QIIiBBH")
STREAM_BODY = struct.Struct(">IIIiIHBBI")
SNAPSHOT_BODY = struct.Struct(">BBBBIIIQIIIiiIIHHIIQQQQ")
assert (DATA_HEADER.size, CONTROL_HEADER.size, RF_BODY.size,
        STREAM_BODY.size, SNAPSHOT_BODY.size) == (64, 32, 24, 28, 96)

COMMANDS = {"SET_RF": 1, "SET_STREAM": 2, "START": 3, "STOP": 4, "GET_STATUS": 5}
STATUSES = dict(enumerate(("OK", "BAD_COMMAND", "BAD_LENGTH", "BAD_PARAMETER",
    "BAD_STATE", "UNSUPPORTED", "BUSY", "HW_TIMEOUT", "HW_FAILURE",
    "BOOT_MISMATCH", "REQUEST_CONFLICT", "STALE_REQUEST", "CONFIG_CONFLICT",
    "CAPTURE_REUSED")))
REQUEST_LENGTHS = {1: 24, 2: 28, 3: 4, 4: 0, 5: 0}


class ProtocolError(ValueError):
    pass


def crc32(data: bytes) -> int:
    return zlib.crc32(data) & 0xffffffff


@dataclass(frozen=True)
class IQHeader:
    stream_id: int = 1
    capture_id: int = 1
    window_seq: int = 0
    fragment_index: int = 0
    sample_index: int = 0
    lo_hz: int = 100_000_000
    fs_eff_hz: int = 1_000_000
    baseband_center_hz: int = 0
    flags: int = 0
    rx_gain_mdB: int = 10_000

    def window_metadata(self) -> tuple:
        return tuple(value for name, value in asdict(self).items() if name != "fragment_index")


def _check_iq(h: IQHeader) -> None:
    if h.stream_id != 1 or not h.capture_id or not h.fs_eff_hz:
        raise ProtocolError("invalid IQ stream/capture/sample rate")
    if not 0 <= h.fragment_index < 4 or h.flags & ~0x0f:
        raise ProtocolError("invalid IQ fragment index or flags")
    if not h.flags & 8 and h.sample_index != h.window_seq * 1024:
        raise ProtocolError("continuous sample_index must equal window_seq * 1024")


def encode_iq(h: IQHeader, payload: bytes) -> bytes:
    _check_iq(h)
    if len(payload) != 1024:
        raise ProtocolError("IQ fragment payload must be 1024 bytes")
    return DATA_HEADER.pack(b"RFIQ", 1, 1, 64, h.stream_id, h.capture_id,
        h.window_seq, h.fragment_index, 4, h.sample_index, h.lo_hz, h.fs_eff_hz,
        h.baseband_center_hz, 256, h.flags, h.rx_gain_mdB, crc32(payload), 0) + payload


def decode_iq(packet: bytes, *, check_crc: bool = True) -> tuple[IQHeader, bytes]:
    if len(packet) != 1088:
        raise ProtocolError("RFIQ UDP payload must be exactly 1088 bytes")
    f = DATA_HEADER.unpack_from(packet)
    if f[:4] != (b"RFIQ", 1, 1, 64) or f[8] != 4 or f[13] != 256 or f[17] != 0:
        raise ProtocolError("invalid RFIQ constants, type, counts or reserved field")
    h = IQHeader(f[4], f[5], f[6], f[7], f[9], f[10], f[11], f[12], f[14], f[15])
    _check_iq(h)
    payload = packet[64:]
    if check_crc and f[16] != crc32(payload):
        raise ProtocolError("RFIQ payload CRC mismatch")
    return h, payload


def fragment_window(iq: bytes, **metadata: int) -> list[bytes]:
    if len(iq) != 4096:
        raise ProtocolError("IQ window must be 4096 bytes / 1024 complex points")
    return [encode_iq(IQHeader(fragment_index=i, **metadata), iq[i*1024:(i+1)*1024])
            for i in range(4)]


@dataclass(frozen=True)
class RFConfig:
    lo_hz: int = 100_000_000
    adc_sample_rate_hz: int = 4_000_000
    rx_bandwidth_hz: int = 800_000
    rx_gain_mdB: int = 10_000
    gain_mode: int = 0
    rx_channel: int = 0

    def pack(self) -> bytes:
        return RF_BODY.pack(*asdict(self).values(), 0)

    @classmethod
    def unpack(cls, body: bytes) -> RFConfig:
        if len(body) != 24:
            raise ProtocolError("SET_RF payload must be 24 bytes")
        f = RF_BODY.unpack(body)
        if f[-1] != 0:
            raise ProtocolError("SET_RF reserved must be zero")
        return cls(*f[:-1])


@dataclass(frozen=True)
class StreamConfig:
    stream_id: int = 1
    fs_eff_hz: int = 1_000_000
    decimation: int = 4
    baseband_center_hz: int = 0
    hop_points: int = 1024
    window_points: int = 1024
    mode: int = 0
    source: int = 1
    max_windows_per_second: int = 0

    def pack(self) -> bytes:
        return STREAM_BODY.pack(*asdict(self).values())

    @classmethod
    def unpack(cls, body: bytes) -> StreamConfig:
        if len(body) != 28:
            raise ProtocolError("SET_STREAM payload must be 28 bytes")
        return cls(*STREAM_BODY.unpack(body))


def validate_configuration(rf: RFConfig, stream: StreamConfig) -> None:
    """Baseline cross-checks only; actual RF ranges/IP capabilities are board-specific."""
    if not rf.lo_hz or not rf.adc_sample_rate_hz or not rf.rx_bandwidth_hz:
        raise ProtocolError("RF frequencies/rates must be nonzero")
    if rf.gain_mode not in (0,1,2) or rf.rx_channel != 0:
        raise ProtocolError("invalid gain mode or RX channel")
    if stream.stream_id != 1 or stream.window_points != 1024 or stream.hop_points != 1024:
        raise ProtocolError("baseline requires stream 1, 1024-point window and hop")
    if stream.mode != 0 or stream.max_windows_per_second or stream.source not in (0, 1):
        raise ProtocolError("baseline requires continuous stream and a known source")
    if stream.decimation < 1 or stream.fs_eff_hz < 1:
        raise ProtocolError("invalid decimation or output sample rate")
    if rf.adc_sample_rate_hz != stream.fs_eff_hz * stream.decimation:
        raise ProtocolError("ADC rate / decimation must exactly equal output rate")


@dataclass(frozen=True)
class Snapshot:
    state: int = 0
    source: int = 0
    mode: int = 0
    rx_channel: int = 0
    active_config_id: int = 0
    capture_id: int = 0
    stream_id: int = 0
    lo_hz: int = 0
    adc_sample_rate_hz: int = 0
    fs_eff_hz: int = 0
    rx_bandwidth_hz: int = 0
    baseband_center_hz: int = 0
    rx_gain_mdB: int = 0
    decimation: int = 0
    hop_points: int = 0
    window_points: int = 0
    status_flags: int = 0
    last_error: int = 0
    fifo_level_points: int = 0
    sample_count: int = 0
    tx_datagrams: int = 0
    drop_windows: int = 0
    overflow_events: int = 0

    def pack(self) -> bytes:
        if self.state not in range(5) or self.status_flags & ~31:
            raise ProtocolError("invalid snapshot state or flags")
        return SNAPSHOT_BODY.pack(*asdict(self).values())

    @classmethod
    def unpack(cls, body: bytes) -> Snapshot:
        if len(body) != 96:
            raise ProtocolError("response snapshot must be 96 bytes")
        result = cls(*SNAPSHOT_BODY.unpack(body))
        result.pack()
        return result


@dataclass(frozen=True)
class ControlMessage:
    kind: int
    request_id: int
    config_id: int
    opcode: int
    status: int
    boot_id: int
    payload: bytes = b""

    def pack(self) -> bytes:
        if self.kind not in (0, 1) or not self.request_id or len(self.payload) > 1440:
            raise ProtocolError("invalid RFCT kind/id/payload length")
        if self.kind == 0 and self.status != 0:
            raise ProtocolError("RFCT request status must be zero")
        if self.kind == 1 and (self.boot_id == 0 or self.status not in STATUSES):
            raise ProtocolError("RFCT response needs boot ID and known status")
        h = CONTROL_HEADER.pack(b"RFCT", 1, self.kind, 32, self.request_id,
            self.config_id, self.opcode, self.status, len(self.payload), self.boot_id, 0)
        packet = h + self.payload
        return packet[:28] + struct.pack(">I", crc32(packet)) + packet[32:]


def decode_control(packet: bytes) -> ControlMessage:
    """Structural decoder; command-level errors are handled by validate_request()."""
    if not 32 <= len(packet) <= 1472:
        raise ProtocolError("invalid RFCT datagram length")
    f = CONTROL_HEADER.unpack_from(packet)
    if f[0] != b"RFCT" or f[1] != 1 or f[3] != 32 or len(packet) != 32 + f[8]:
        raise ProtocolError("invalid RFCT magic/version/header/payload length")
    if crc32(packet[:28] + bytes(4) + packet[32:]) != f[10]:
        raise ProtocolError("RFCT whole-message CRC mismatch")
    result = ControlMessage(f[2], f[4], f[5], f[6], f[7], f[9], packet[32:])
    result.pack()  # Check structural kind/status/id constraints.
    if result.kind == 1:
        Snapshot.unpack(result.payload)
    return result


def validate_request(message: ControlMessage) -> None:
    if message.kind != 0 or message.opcode not in REQUEST_LENGTHS:
        raise ProtocolError("not a supported RFCT request")
    if len(message.payload) != REQUEST_LENGTHS[message.opcode]:
        raise ProtocolError("wrong command payload length")
    if message.opcode in (4, 5):
        if message.config_id:
            raise ProtocolError("STOP/GET_STATUS config_id must be zero")
    elif not message.config_id:
        raise ProtocolError("configuration command config_id must be nonzero")
    if message.boot_id == 0 and message.opcode != 5:
        raise ProtocolError("only GET_STATUS may discover boot_id zero")
    if message.opcode == 1:
        RFConfig.unpack(message.payload)
    if message.opcode == 2:
        StreamConfig.unpack(message.payload)
    if message.opcode == 3 and struct.unpack(">I", message.payload)[0] == 0:
        raise ProtocolError("START capture_id must be nonzero")


@dataclass(frozen=True)
class IQWindow:
    header: IQHeader
    payload: bytes


class IQReassembler:
    """One acknowledged capture. New START requires a new instance.

    Socket peer/UDP checksum checking belongs to the caller/OS. `now` is a
    monotonic timestamp in seconds; explicit timestamps enable deterministic tests.
    """
    def __init__(self, capture_id: int, *, timeout: float = .100, depth: int = 256,
                 expected: dict[str, int] | None = None, event_mode: bool = False):
        if capture_id <= 0 or timeout <= 0 or depth <= 0:
            raise ValueError("capture, timeout and depth must be positive")
        self.capture_id, self.timeout, self.depth = capture_id, timeout, depth
        self.expected = dict(expected or {})
        self.event_mode = event_mode
        self.last_sample_index = -1
        allowed = set(IQHeader.__dataclass_fields__) - {"capture_id", "window_seq",
            "fragment_index", "sample_index", "flags"}
        if set(self.expected) - allowed:
            raise ValueError("expected contains unsupported metadata keys")
        self.pending: dict[int, dict] = {}
        self.retired: set[int] = set()
        self.highest = self.published = -1
        self.counts: Counter = Counter()

    def expire(self, now: float | None = None) -> None:
        now = time.monotonic() if now is None else now
        for seq, item in list(self.pending.items()):
            if now - item["first"] >= self.timeout:
                del self.pending[seq]
                self.retired.add(seq)
                self.counts["timeout"] += 1

    def _advance(self, seq: int) -> None:
        self.highest = max(seq, self.highest)
        cutoff = self.highest - self.depth + 1
        for old in [n for n in self.pending if n < cutoff]:
            del self.pending[old]
            self.counts["evicted"] += 1
        self.retired = {n for n in self.retired if n >= cutoff}

    def _reject(self, seq: int, reason: str) -> None:
        self.pending.pop(seq, None)
        self.retired.add(seq)
        self.counts[reason] += 1
        raise ProtocolError(reason)

    def feed(self, packet: bytes, now: float | None = None) -> IQWindow | None:
        now = time.monotonic() if now is None else now
        self.expire(now)
        h, payload = decode_iq(packet, check_crc=False)
        if h.capture_id != self.capture_id:
            self.counts["wrong_capture"] += 1
            return None
        seq = h.window_seq
        if seq <= self.published or seq <= self.highest - self.depth or seq in self.retired:
            self.counts["late_or_duplicate"] += 1
            return None
        self._advance(seq)
        if bool(h.flags & 8) != self.event_mode:
            self._reject(seq, "mode_mismatch")
        if any(getattr(h, name) != value for name, value in self.expected.items()):
            self._reject(seq, "configuration_mismatch")
        if DATA_HEADER.unpack_from(packet)[16] != crc32(payload):
            self._reject(seq, "crc_failure")
        item = self.pending.setdefault(seq, {"first": now, "header": h, "parts": {}})
        if item["header"].window_metadata() != h.window_metadata():
            self._reject(seq, "header_mismatch")
        parts = item["parts"]
        if h.fragment_index in parts:
            if parts[h.fragment_index] != payload:
                self._reject(seq, "conflicting_duplicate")
            self.counts["duplicate_fragment"] += 1
            return None
        parts[h.fragment_index] = payload
        if len(parts) != 4:
            return None
        assembled = b"".join(parts[i] for i in range(4))
        if h.sample_index <= self.last_sample_index:
            self._reject(seq, "nonmonotonic_sample_index")
        self.last_sample_index = h.sample_index
        previous = self.published
        self.published = seq
        for old in [n for n in self.pending if n <= seq]:
            del self.pending[old]
            self.retired.add(old)
            if old != seq:
                self.counts["late_window"] += 1
        if seq != previous + 1 or h.flags & 1:
            self.counts["gap"] += 1
        self.counts["complete"] += 1
        return IQWindow(item["header"], assembled)
