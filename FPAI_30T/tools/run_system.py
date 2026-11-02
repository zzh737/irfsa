"""Launch the current native worker and PS service."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
from datetime import datetime

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=ROOT / "config/system_v6_hw23.json")
    parser.add_argument("--worker", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--state", type=Path, default=ROOT / "run/controller.sqlite")
    parser.add_argument("--windows", type=int, default=16)
    parser.add_argument("--duration", type=float, default=10)
    parser.add_argument("--continuous", action="store_true")
    parser.add_argument("--replay-only", action="store_true")
    parser.add_argument("--capture", type=int)
    args = parser.parse_args()
    if args.replay_only != (args.capture is not None):
        parser.error("--replay-only and --capture must be supplied together")
    config = json.loads(args.config.read_text(encoding="utf-8"))
    if config["backend"] not in ("native-host", "native-board"):
        parser.error("launcher expects native-host/native-board config")
    model_dir = ROOT / "npu/v6"
    model_json = model_dir / "model.json"
    model_raw = model_dir / "model.raw"
    if not model_json.is_file() or not model_raw.is_file():
        raise RuntimeError("Current v6 model files are missing")
    output = args.output or ROOT / "run" / datetime.now().strftime("session_%Y%m%d_%H%M%S_%f")
    output.parent.mkdir(parents=True, exist_ok=True)
    log_path = Path(str(output) + "_worker.log")
    command = [str(args.worker.resolve()), "--host" if config["backend"] == "native-host" else "--board",
               str(model_json), str(model_raw), str(config["worker_port"])]
    with log_path.open("x", encoding="utf-8") as log:
        child_options = ({"creationflags": subprocess.CREATE_NEW_PROCESS_GROUP}
                         if os.name == "nt" else {"start_new_session": True})
        worker = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, **child_options)
        service = None
        try:
            deadline = time.monotonic() + 60
            while b"RF_WORKER_READY " not in log_path.read_bytes():
                if worker.poll() is not None or time.monotonic() > deadline:
                    raise RuntimeError(f"Worker failed to become ready; see {log_path}")
                time.sleep(0.05)
            call = [sys.executable, "-B", str(ROOT / "ps/system/service.py"), "--config", str(args.config),
                    "--output", str(output), "--state", str(args.state), "--windows", str(args.windows),
                    "--duration", str(args.duration)]
            if args.continuous:
                call.append("--continuous")
            if args.replay_only:
                call.extend(["--replay-only", "--capture", str(args.capture)])
            service = subprocess.Popen(call, **child_options)
            try:
                return service.wait()
            except KeyboardInterrupt:
                service.send_signal(signal.CTRL_BREAK_EVENT if os.name == "nt" else signal.SIGINT)
                return service.wait(timeout=30)
        finally:
            if service is None or service.poll() is not None:
                try:
                    worker.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    print(f"Worker pid={worker.pid} remains active; log={log_path}", file=sys.stderr)


if __name__ == "__main__":
    raise SystemExit(main())
