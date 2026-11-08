"""Package the hold-sweep Alpha under the normal ForeverVanguard addon name."""
from pathlib import Path
import hashlib, os, subprocess, sys, tempfile, zipfile
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SOURCE = HERE/'ForeverVanguardSweepTest'
subprocess.run([sys.executable, str(HERE/'test_probe.py')], check=True)
files = {p.name:p.read_bytes() for p in SOURCE.iterdir() if p.is_file()}
toc = files.pop('ForeverVanguardSweepTest.toc').decode()
toc = toc.replace('Forever Vanguard - Hold Sweep TEST', 'Forever Vanguard').replace('0.2.0-sweep-test.1', '0.2.1').replace(' Disable normal Forever Vanguard while testing.', '')
files['ForeverVanguard.toc'] = toc.encode()
files['SweepTest.lua'] = files['SweepTest.lua'].replace(b'0.2.0-sweep-test.1', b'0.2.1').replace(b'FV Sweep Test:', b'Forever Vanguard:').replace(b' Disable normal Forever Vanguard.', b'')
files['README.txt'] = b'''Forever Vanguard 0.2.1 - Alpha\n\nInstall the ForeverVanguard folder in Interface/AddOns, replacing the previous version.\nDisable/remove the separate ForeverVanguardSweepTest addon if previously installed.\nThis Alpha tests holding Mouse 4 while sweeping across mobs, in and out of combat.\nClear any existing Mouse 4 game binding before testing. No macro setup is needed.\n\nHold Mouse 4, move across mobs, then release. /fvtest click selects the alternate\nsecure-button probe; /fvtest direct restores the default direct-call probe.\n/fvtest reset clears attempt reservations outside combat with the button released.\n/fvtest report opens a copyable log. /fvtest off stops the probe.\n\nExperimental: real Forever marking and combat permissions are NOT yet verified.\nThe probe skips unreadable marker information, preserves readable existing marks,\nand reserves attempted icons rather than recycling them, even on failures.\nIt stops after all eight icons are reserved. Reset between test runs if needed.\nCALL returned is not proof of success. CONFIRMED requires a matching readable mark\non the same hovered mob. UNVERIFIED means readback was unavailable or you moved away.\nSend the report plus whether you visually saw the icons, in/out of combat.\nLogs are saved per character in ForeverVanguard.lua SavedVariables after logout/reload.\nThe older settings screen and click-per-mob mode are not included in this test Alpha.\n'''
out = ROOT/'dist/ForeverVanguard-0.2.1.zip'
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
 for name, data in sorted(files.items()):z.writestr('ForeverVanguard/'+name,data)
with tempfile.TemporaryDirectory() as d:
 with zipfile.ZipFile(out) as z:
  assert z.testzip() is None
  z.extractall(d)
 env = dict(os.environ,FV_SWEEP_SOURCE=str(Path(d)/'ForeverVanguard/SweepTest.lua'))
 subprocess.run([sys.executable,str(HERE/'test_probe.py')],env=env,check=True)
digest=hashlib.sha256(out.read_bytes()).hexdigest()
out.with_suffix('.zip.sha256').write_text(digest+'  '+out.name+'\n')
print(out);print(digest)
