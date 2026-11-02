#!/usr/bin/env bash
set -euo pipefail
fpai_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$(uname -m)" != aarch64 || "$EUID" -ne 0 ]]; then
    echo 'Run as root on the AArch64 Ubuntu board.' >&2
    exit 2
fi
python3 -c 'import sys, sqlite3; assert sys.version_info >= (3, 8), "Python >=3.8 required"'
dpkg -i \
    "$fpai_root"/vendor/ubuntu20_target_deps/libbz2-1.0_*.deb \
    "$fpai_root"/vendor/ubuntu20_target_deps/libelf1_*.deb \
    "$fpai_root"/vendor/ubuntu20_target_deps/libdw1_*.deb \
    "$fpai_root"/vendor/ubuntu20_target_deps/liblzma5_*.deb \
    "$fpai_root"/vendor/ubuntu20_target_deps/zlib1g_*.deb \
    "$fpai_root"/vendor/icraft3361_onchip/Icraft_3.36.1_onchip.deb \
    "$fpai_root"/vendor/icraft3361_onchip/CustomOp_3.36.1_onchip.deb
ldconfig
echo 'Runtime packages installed.'
