"""Validate, package, and test the actual local development artifact."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import hashlib, io, re, shutil, subprocess, sys, tempfile
ROOT=Path(__file__).resolve().parent
subprocess.run([sys.executable,str(ROOT/'tests/test_vanguard.py')],check=True)
toc_source=(ROOT/'ForeverVanguard/ForeverVanguard.toc').read_text()
version=re.search(r'^## Version: ([0-9.]+)$',toc_source,re.M).group(1)
files={f'ForeverVanguard/{p.name}':p for p in (ROOT/'ForeverVanguard').iterdir() if p.suffix in {'.lua','.toc','.xml'}}
files['ForeverVanguard/README.md']=ROOT/'README.md'
files['ForeverVanguard/CHANGELOG.md']=ROOT/'CHANGELOG.md'
files['ForeverVanguard/TESTING.md']=ROOT/'TESTING.md'
def build():
    data=io.BytesIO()
    with ZipFile(data,'w') as archive:
        for name,path in sorted(files.items()):
            assert not path.is_symlink()
            item=ZipInfo(name,(2026,11,7,0,0,0));item.compress_type=ZIP_DEFLATED
            item.create_system=3;item.external_attr=0o100644<<16
            archive.writestr(item,path.read_bytes())
    return data.getvalue()
data=build();assert data==build()
with ZipFile(io.BytesIO(data)) as archive:
    assert archive.testzip() is None
    assert len(set(archive.namelist()))==len(archive.namelist())
    assert all(n.startswith('ForeverVanguard/') and '..' not in n.split('/') for n in archive.namelist())
    toc=archive.read('ForeverVanguard/ForeverVanguard.toc').decode()
    assert '## Interface: 16001' in toc and f'## Version: {version}' in toc
    assert 'ForeverVanguard/ForeverVanguard.lua' in archive.namelist()
    assert not any('SweepTest' in n for n in archive.namelist())
    main=archive.read('ForeverVanguard/ForeverVanguard.lua').decode()
    assert 'SLASH_FOREVERVANGUARD1 = "/fv"' in main
    for line in toc.splitlines():
        if line and not line.startswith('#'):assert 'ForeverVanguard/'+line in archive.namelist()
    with tempfile.TemporaryDirectory(prefix='vanguard-check-') as directory:
        archive.extractall(directory)
        shutil.copytree(ROOT/'tests',Path(directory)/'tests',ignore=shutil.ignore_patterns('__pycache__'))
        subprocess.run([sys.executable,str(Path(directory)/'tests/test_vanguard.py')],check=True)
out=ROOT/f'dist/local-only/ForeverVanguard-{version}.zip';out.parent.mkdir(parents=True,exist_ok=True)
out.write_bytes(data);digest=hashlib.sha256(data).hexdigest()
out.with_suffix('.zip.sha256').write_text(f'{digest}  {out.name}\n')
print(out);print(digest);print('Local development package verified. Live-client validation remains pending.')
