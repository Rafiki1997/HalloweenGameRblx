"""Upload asset collections with the installed "Upload to Roblox" add-on's own client, headless.

Run with Blender closed:
  blender --background --disable-autoexec --python-exit-code 1 --python tools/blender/upload_via_addon.py -- [names...]

Uses the login saved by the add-on's panel. Roblox rotates refresh tokens on every refresh, so the
rotated token is written back to the add-on preferences and saved, the same way the panel does.
No credential value is ever printed. Uploads are sequential and each waits for completion. Asset
IDs are written to the collections in town.blend so `harvest_ids.py` records them in the manifest;
collections that already have an ID are uploaded as new versions of that asset.
"""
import asyncio
import importlib
import json
import sys
import time
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
BLEND = ROOT/'assets/town.blend'
EXPORTS = ROOT/'assets/exports'
MANIFEST = ROOT/'assets/manifest.json'
ADDON = 'roblox-blender-plugin'


def log(msg):
    print(f'UPLOAD {msg}', flush=True)


def persist_login(wm, creator_details):
    """Copy the (possibly rotated) refresh token into add-on preferences and save user preferences."""
    creator_details.save_creator_details(wm, bpy.context.preferences)
    bpy.ops.wm.save_userpref()


async def main(names):
    lib = lambda m: importlib.import_module(f'{ADDON}.lib.{m}')
    constants = lib('constants'); creator_details = lib('creator_details'); oauth2 = lib('oauth2_client')
    from assets_upload_client import AssetsUploadClient
    from openapi_client.models import (RobloxOpenCloudAssetsV1Creator as AssetsCreator,
                                       RobloxOpenCloudAssetsV1AssetType as AssetType)
    # Open the blend first, keeping the session window manager (the add-on stores its creator list on it).
    bpy.ops.wm.open_mainfile(filepath=str(BLEND), use_scripts=False, load_ui=False)
    wm = bpy.context.window_manager
    creator_details.load_creator_details(wm, bpy.context.preferences)
    client = oauth2.RbxOAuth2Client(wm.rbx)
    if not client.token_data.get('refresh_token'):
        log('no saved login; starting the add-on browser login. Approve it in the browser tab that opens.')
        await client.login(); persist_login(wm, creator_details); log('browser login completed and saved to add-on preferences')

    async def ensure_login():
        before = client.token_data.get('refresh_token')
        try:
            await client.refresh_login_if_needed()
        except Exception as exception:
            status = getattr(exception, 'status', None); message = getattr(exception, 'message', '') or str(exception)
            log(f'saved login unusable (HTTP {status} {str(message)[:120]}); starting the add-on browser login. Approve it in the browser tab that opens.')
            await client.login()
            persist_login(wm, creator_details); log('browser login completed and saved to add-on preferences')
        if client.token_data.get('refresh_token') != before:
            persist_login(wm, creator_details)
            log('login refreshed and saved to add-on preferences')

    await ensure_login()
    creator_data = creator_details.get_selected_creator_data(wm)
    if creator_data is None:
        raise SystemExit('No creator selected in the add-on; pick one in the Roblox tab once.')
    log(f'creator {creator_data.type} id={creator_data.id} name={creator_data.name}')
    creator = AssetsCreator(user_id=int(creator_data.id)) if creator_data.type == 'USER' else AssetsCreator(group_id=int(creator_data.id))

    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    targets = names or sorted(manifest['assets'])
    results = {}
    for name in targets:
        collection = bpy.data.collections.get(name)
        fbx = EXPORTS/f'{name}.fbx'
        if collection is None or not fbx.is_file():
            log(f'{name}: SKIP (missing collection or FBX)'); continue
        existing = str(collection.get(constants.RBX_PACKAGE_ID_PROPERTY_NAME, '') or '')
        asset_id = int(existing) if existing.isdigit() else 0
        await ensure_login()
        started = time.time()
        try:
            async with AssetsUploadClient(creator=creator, oauth2_token=client.token_data['access_token']) as uploader:
                operation = await uploader.upload_asset_and_wait_for_done_async(
                    asset_type=AssetType.MODEL, asset_name=name, asset_description=constants.ASSET_DESCRIPTION,
                    file_path=str(fbx), asset_id=asset_id, upload_request_timeout_seconds=90,
                    num_poll_status_tries=60, poll_status_request_timeout_seconds=10)
        except Exception as exception:  # report verbatim, keep going
            log(f'{name}: ERROR {type(exception).__name__}: {str(exception)[:300]}'); results[name] = 'error'; continue
        elapsed = time.time()-started
        if operation.error:
            log(f'{name}: FAILED {operation.error.code}: {operation.error.message} ({elapsed:.0f}s)'); results[name] = 'failed'
        elif not operation.done:
            log(f'{name}: TIMEOUT polling after {elapsed:.0f}s; asset may still finish'); results[name] = 'timeout'
        elif operation.response:
            new_id = int(operation.response.asset_id)
            collection[constants.RBX_PACKAGE_ID_PROPERTY_NAME] = str(new_id)
            verb = 'new version' if asset_id else 'created'
            log(f'{name}: OK {verb} assetId={new_id} revision={operation.response.revision_id} ({elapsed:.0f}s)'); results[name] = 'ok'
        else:
            log(f'{name}: INVALID RESPONSE'); results[name] = 'invalid'
    bpy.ops.wm.save_mainfile(filepath=str(BLEND))
    ok = sum(1 for v in results.values() if v == 'ok')
    log(f'SUMMARY {ok}/{len(results)} succeeded; problems: ' + (', '.join(f'{k}={v}' for k, v in results.items() if v != 'ok') or 'none'))
    return all(v == 'ok' for v in results.values())


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    # Run on the add-on's own event loop: its browser-login callback server binds to that loop.
    event_loop = importlib.import_module(f'{ADDON}.lib.event_loop')
    loop = event_loop.get_loop(); asyncio.set_event_loop(loop)
    success = loop.run_until_complete(main(args))
    sys.exit(0 if success else 2)
