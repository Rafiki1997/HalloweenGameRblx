"""Widen the Roblox Blender add-on's upload wait so slow mesh processing does not report a timeout.

The stock add-on (Upload to Roblox 1.0.5) waits 25 s for the upload request and then polls the
operation only 5 times, 5 s apart. Roblox often needs longer to process a multi-mesh model, so the
add-on reports "Operation Timed Out" even though the asset was created, and the collection never
receives its `Roblox Package ID`. Re-uploading then creates a duplicate asset.

This patch is idempotent, keeps `upload_operator.py.orig`, and must be applied while Blender is
closed (the module is loaded at start-up). Re-run after reinstalling or updating the add-on.
"""
import os
from pathlib import Path
import sys

ADDON = Path(os.environ['APPDATA']) / 'Blender Foundation/Blender/5.1/scripts/addons/roblox-blender-plugin/lib/upload_operator.py'
OLD = """                asset_id=package_id or NO_ASSET_ID,
                upload_request_timeout_seconds=25,
            )"""
NEW = """                asset_id=package_id or NO_ASSET_ID,
                # Patched for Ghostlight Hollow: Roblox mesh processing regularly exceeds the stock
                # 25 s request timeout and 5 x 5 s polling window, which reported "Operation Timed Out"
                # after the asset had actually been created. Wait up to 90 s for the request and poll
                # for up to 5 minutes. Original file kept as upload_operator.py.orig.
                upload_request_timeout_seconds=90,
                num_poll_status_tries=60,
                poll_status_request_timeout_seconds=10,
            )"""

if __name__ == '__main__':
    if not ADDON.is_file():
        sys.exit(f'add-on not found at {ADDON}')
    source = ADDON.read_text(encoding='utf-8')
    if NEW in source:
        print('already patched'); sys.exit(0)
    if source.count(OLD) != 1:
        sys.exit('unexpected add-on source; refusing to patch')
    backup = ADDON.with_suffix('.py.orig')
    if not backup.exists():
        backup.write_text(source, encoding='utf-8')
    ADDON.write_text(source.replace(OLD, NEW), encoding='utf-8')
    print(f'patched {ADDON} (backup at {backup.name})')
