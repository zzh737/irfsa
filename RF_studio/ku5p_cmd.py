"""Send commands to a running KU5P Radio Studio (its console `serve` port).

    python ku5p_cmd.py "set mod 256QAM offset 0.15" upload "wait 60" status
    python ku5p_cmd.py --port 47100 check

Each argument is one console command. Replies are printed as "<level> <text>".
Exit code 1 if any reply line is an error. Only connects to 127.0.0.1.
"""
import argparse
import socket
import sys


def send(commands, port=47100, timeout=600):
    out = []
    with socket.create_connection(('127.0.0.1', port), timeout=timeout) as s:
        f = s.makefile('rwb')
        for cmd in commands:
            f.write((cmd + '\n').encode('utf-8'))
            f.flush()
            block = []
            while True:
                line = f.readline()
                if not line:
                    raise ConnectionError('KU5P Radio Studio closed the command port')
                line = line.decode('utf-8').rstrip('\n')
                if line == '.':
                    break
                level, _, text = line.partition(' ')
                block.append((level, text))
            out.append((cmd, block))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--port', type=int, default=47100)
    ap.add_argument('commands', nargs='+')
    args = ap.parse_args()
    failed = False
    try:
        for cmd, block in send(args.commands, args.port):
            print('> ' + cmd)
            for level, text in block:
                print(f'{level} {text}')
                failed |= level == 'error'
    except OSError as exc:
        print(f'error 无法连接 127.0.0.1:{args.port}：{exc}（请在界面控制台输入 serve，或以 --serve 启动）')
        return 2
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
