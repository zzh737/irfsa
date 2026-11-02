"""Short hardware echo check for the supplied PZ UDP reference image."""
import datetime
import hashlib
import json
import socket
import time
from pathlib import Path

HOST = '192.168.1.112'
BOARD = ('192.168.1.10', 1234)
output = Path(__file__).resolve().parents[1] / 'reports/hardware_fix_20261024/original_udp_echo.json'
result = {'time': datetime.datetime.now().astimezone().isoformat(),
          'local': [HOST, 1234], 'remote': list(BOARD), 'tests': []}
try:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.bind((HOST, 1234))
        sock.settimeout(0.8)
        for sequence, size in enumerate([64, 256, 1024, 1400] * 3):
            payload = sequence.to_bytes(4, 'big') + bytes((i * 37 + sequence) & 255 for i in range(size - 4))
            entry = {'sequence': sequence, 'bytes': size,
                     'sha256_sent': hashlib.sha256(payload).hexdigest()}
            start = time.perf_counter()
            sock.sendto(payload, BOARD)
            try:
                data, peer = sock.recvfrom(65535)
                entry.update(peer=list(peer), received_bytes=len(data),
                             rtt_ms=round((time.perf_counter() - start) * 1000, 3),
                             sha256_received=hashlib.sha256(data).hexdigest(),
                             passed=(data == payload and peer == BOARD))
            except socket.timeout:
                entry.update(passed=False, error='timeout')
            result['tests'].append(entry)
            print(json.dumps(entry), flush=True)
            time.sleep(0.02)
except OSError as exc:
    result['error'] = str(exc)
finally:
    result['passed'] = sum(x['passed'] for x in result['tests'])
    result['total'] = len(result['tests'])
    output.write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(f"Passed {result['passed']}/{result['total']}; report: {output}")
