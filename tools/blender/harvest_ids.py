"""After the human upload, save and close town.blend, then run with headless Blender."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import bpy

ROOT=Path(__file__).resolve().parents[2]
manifest_path=ROOT/'assets/manifest.json'
manifest=json.loads(manifest_path.read_text())
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets/town.blend'),use_scripts=False)
missing=[]
for name,asset in manifest['assets'].items():
    collection=bpy.data.collections.get(name)
    raw=collection.get('Roblox Package ID','') if collection else ''
    if not str(raw).isdigit() or not 0<int(raw)<=2**53-1:
        missing.append(name)
        continue
    fbx=ROOT/'assets/exports'/f'{name}.fbx'
    digest=hashlib.sha256(fbx.read_bytes()).hexdigest()
    if asset.get('assetId')!=int(raw) or asset.get('sha256')!=digest:
        asset['uploadedAt']=datetime.now(timezone.utc).isoformat()
    asset['assetId']=int(raw)
    asset['sha256']=digest
    print(f'{name}: assetId={int(raw)}')
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
if missing: raise RuntimeError('Not uploaded: '+', '.join(missing))
print('HARVEST PASS: all collection IDs recorded')
