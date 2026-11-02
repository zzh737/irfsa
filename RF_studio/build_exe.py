"""Rebuild the Windows executable with an isolated PyInstaller installation."""
import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parent
parser=argparse.ArgumentParser()
parser.add_argument('--dist-dir',default=str(ROOT),help='Build separately before replacing a running release')
args=parser.parse_args()
env=dict(os.environ)
env['PYTHONPATH']=str(ROOT/'.build_deps')
command=[sys.executable,'-m','PyInstaller','--noconfirm','--clean','--onefile','--windowed',
         '--name','KU5P_Radio_Studio','--distpath',str(Path(args.dist_dir).resolve()),'--workpath',str(ROOT/'.build'),
         '--specpath',str(ROOT/'.build'),'--paths',str(ROOT/'core'),'--paths',str(ROOT/'vendor'),
         '--collect-all','onnxruntime','--hidden-import','model_eval',
         '--icon',str(ROOT/'assets/radio.ico'),'--add-data',str(ROOT/'assets')+';assets',
         str(ROOT/'app.py')]
subprocess.run(command,cwd=ROOT,env=env,check=True)
