"""Build an isolated local probe. Never package it as the production addon."""
from pathlib import Path
import hashlib, os, subprocess, sys, tempfile, zipfile
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SOURCE = HERE/'ForeverVanguardSweepTest'
subprocess.run([sys.executable, str(HERE/'test_probe.py')], check=True)
out = ROOT/'dist/local-only/ForeverVanguardSweepTest.zip'
out.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for p in sorted(SOURCE.iterdir()):
        if p.is_file(): z.write(p, 'ForeverVanguardSweepTest/'+p.name)
with tempfile.TemporaryDirectory() as d:
    with zipfile.ZipFile(out) as z:
        assert z.testzip() is None
        assert all(n.startswith('ForeverVanguardSweepTest/') for n in z.namelist())
        z.extractall(d)
    env = dict(os.environ, FV_SWEEP_SOURCE=str(Path(d)/'ForeverVanguardSweepTest/SweepTest.lua'))
    subprocess.run([sys.executable, str(HERE/'test_probe.py')], env=env, check=True)
print(out)
print(hashlib.sha256(out.read_bytes()).hexdigest())
print('Isolated local probe only. Do not publish as a Forever Vanguard update.')
