"""Verify the candidate and source identity without accessing hardware."""
from pathlib import Path
import hashlib
import json

R=Path(__file__).resolve().parents[1]

def verify():
    manifest=R/'reports/system_build/release_manifest.json'
    m=json.loads(manifest.read_text(encoding='utf-8'))
    bit=R/m['artifact']
    if hashlib.sha256(bit.read_bytes()).hexdigest()!=m['sha256']:
        raise RuntimeError('Candidate bitstream does not match release manifest')
    if min(m['setup_WNS_ns'],m['hold_WHS_ns'])<0:
        raise RuntimeError('Candidate has a timing violation')
    for filename,expected in m['inputs'].items():
        if hashlib.sha256((R/filename).read_bytes()).hexdigest()!=expected:
            raise RuntimeError('Design input changed; rebuild before programming: '+filename)
    if not m['checks'] or any(x.get('passed') is not True for x in m['checks'].values()):
        raise RuntimeError('Incomplete offline acceptance checks')
    for filename,expected in m['evidence_sha256'].items():
        if hashlib.sha256((R/filename).read_bytes()).hexdigest()!=expected:
            raise RuntimeError('Acceptance evidence changed; review and regenerate manifest: '+filename)
    return bit,m

if __name__=='__main__':
    bit,m=verify()
    print('Candidate identity and offline checks verified: '+str(bit))
    print('SHA256 '+m['sha256'])
    print('Hardware verification remains pending.')
