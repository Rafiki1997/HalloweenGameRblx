"""Package the exact Luau sources into an openable Roblox XML place. No dependencies."""
from pathlib import Path
import xml.etree.ElementTree as ET
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build' / 'GhostlightHollow.rbxlx'

def item(parent, cls, name):
    node = ET.SubElement(parent, 'Item', {'class': cls, 'referent': 'RBX' + hashlib.sha1((cls + name + str(len(list(parent)))).encode()).hexdigest()})
    props = ET.SubElement(node, 'Properties')
    ET.SubElement(props, 'string', {'name': 'Name'}).text = name
    return node, props

def sources(parent, folder):
    for child in sorted(p for p in folder.iterdir() if p.is_dir()):
        node, _ = item(parent, 'Folder', child.name)
        sources(node, child)
    for path in sorted(folder.glob('*.luau')):
        if path.name.endswith('.server.luau'):
            cls, name = 'Script', path.name.removesuffix('.server.luau')
        elif path.name.endswith('.client.luau'):
            cls, name = 'LocalScript', path.name.removesuffix('.client.luau')
        else:
            cls, name = 'ModuleScript', path.stem
        node, props = item(parent, cls, name)
        ET.SubElement(props, 'ProtectedString', {'name': 'Source'}).text = path.read_text(encoding='utf-8')
        if cls != 'ModuleScript':
            ET.SubElement(props, 'bool', {'name': 'Disabled'}).text = 'false'

def build():
    test_mode = '--test' in sys.argv
    preview_mode = '--preview' in sys.argv
    ui_preview = '--ui-preview' in sys.argv
    destination = OUT.with_name('GhostlightHollow-UIPreview.rbxlx') if ui_preview else OUT.with_name('GhostlightHollow-ReferencePreview.rbxlx') if preview_mode else OUT.with_name('GhostlightHollow.Acceptance.rbxlx') if test_mode else OUT
    root = ET.Element('roblox', {'version': '4'})
    ET.SubElement(root, 'External').text = 'null'
    ET.SubElement(root, 'External').text = 'nil'
    workspace, props = item(root, 'Workspace', 'Workspace')
    ET.SubElement(props, 'bool', {'name': 'StreamingEnabled'}).text = 'false'
    _, terrain_props = item(workspace, 'Terrain', 'Terrain')
    ET.SubElement(terrain_props, 'bool', {'name': 'Decoration'}).text = 'true'  # grass blades on Grass terrain; not scriptable
    _, lighting_props = item(root, 'Lighting', 'Lighting')
    ET.SubElement(lighting_props, 'token', {'name': 'Technology'}).text = '4'  # Enum.Technology.Future: shadowed point lights, specular
    rep, _ = item(root, 'ReplicatedStorage', 'ReplicatedStorage')
    shared, _ = item(rep, 'Folder', 'Ghostlight')
    sources(shared, ROOT / 'src/shared')
    server, _ = item(root, 'ServerScriptService', 'ServerScriptService')
    scripts, _ = item(server, 'Folder', 'GhostlightServer')
    sources(scripts, ROOT / 'src/server')
    starter, _ = item(root, 'StarterPlayer', 'StarterPlayer')
    player_scripts, _ = item(starter, 'StarterPlayerScripts', 'StarterPlayerScripts')
    client, _ = item(player_scripts, 'Folder', 'GhostlightClient')
    sources(client, ROOT / 'src/client')
    if ui_preview:
        _, props = item(client, 'ModuleScript', 'UIAcceptance')
        ET.SubElement(props, 'ProtectedString', {'name': 'Source'}).text = (ROOT / 'tests/UIAcceptance.luau').read_text(encoding='utf-8')
        for node in client.findall('Item'):
            if node.find('Properties/string[@name="Name"]').text == 'Main':
                node.find('Properties/ProtectedString[@name="Source"]').text += '\ntask.spawn(function() require(script.Parent.UIAcceptance)(ui,render,closePanel,ghostCard) end)\n'
    if preview_mode:
        _, props = item(player_scripts, 'LocalScript', 'ReferenceCamera')
        ET.SubElement(props, 'ProtectedString', {'name': 'Source'}).text = (ROOT / 'tools/ReferenceCamera.client.luau').read_text(encoding='utf-8')
        _, props = item(scripts, 'Script', 'ReferenceAcceptance')
        ET.SubElement(props, 'ProtectedString', {'name': 'Source'}).text = (ROOT / 'tools/ReferenceAcceptance.server.luau').read_text(encoding='utf-8')
        _, props = item(scripts, 'Script', 'InteriorAcceptance')
        ET.SubElement(props, 'ProtectedString', {'name': 'Source'}).text = (ROOT / 'tools/InteriorAcceptance.server.luau').read_text(encoding='utf-8')
    if test_mode:
        for parent, cls, filename in [(scripts, 'Script', 'RuntimeAcceptance.server.luau'), (client, 'LocalScript', 'RuntimeAcceptance.client.luau')]:
            _, props = item(parent, cls, 'RuntimeAcceptance')
            ET.SubElement(props, 'ProtectedString', {'name': 'Source'}).text = (ROOT / 'tests' / filename).read_text(encoding='utf-8')
    item(root, 'StarterGui', 'StarterGui')
    item(root, 'SoundService', 'SoundService')
    OUT.parent.mkdir(exist_ok=True)
    ET.indent(root)
    ET.ElementTree(root).write(destination, encoding='utf-8', xml_declaration=True)
    manifest = {str(p.relative_to(ROOT)).replace('\\', '/'): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT / 'src').rglob('*.luau'))}
    (OUT.parent / 'source-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Built {destination.name}: {len(manifest)} production scripts, {destination.stat().st_size:,} bytes')

if __name__ == '__main__':
    build()
