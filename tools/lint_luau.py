"""Scope lint for Luau scripts, driven by the bundled luau-ast parser.

Luau resolves names at parse time. A file-level `local` that is referenced above its declaration is
compiled as a global read, which is nil at runtime in Roblox. luau-compile accepts it, so this lint
exists to fail the build instead. It also rejects any other global that is not a known Luau or Roblox
global, which catches services used without a `GetService` line.
"""
from pathlib import Path
import json
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
AST_BIN=ROOT/'.tools/luau/luau-ast.exe'

ALLOWED_GLOBALS={
    # Luau
    'assert','collectgarbage','error','gcinfo','getmetatable','ipairs','loadstring','newproxy','next','pairs',
    'pcall','print','rawequal','rawget','rawlen','rawset','require','select','setmetatable','tonumber','tostring',
    'type','typeof','unpack','xpcall','_G','_VERSION','bit32','buffer','coroutine','debug','math','os','string',
    'table','utf8','vector',
    # Roblox globals and datatypes
    'game','workspace','script','plugin','shared','Instance','Enum','Axes','BrickColor','CFrame','CatalogSearchParams',
    'Color3','ColorSequence','ColorSequenceKeypoint','Content','DateTime','DockWidgetPluginGuiInfo','Faces',
    'FloatCurveKey','Font','NumberRange','NumberSequence','NumberSequenceKeypoint','OverlapParams','Path2DControlPoint',
    'PathWaypoint','PhysicalProperties','Random','Ray','RaycastParams','Rect','Region3','Region3int16','RotationCurveKey',
    'SecurityCapabilities','SharedTable','TweenInfo','UDim','UDim2','Vector2','Vector2int16','Vector3','Vector3int16',
    'task','tick','time','wait','delay','spawn','elapsedTime','settings','UserSettings','version','warn','printidentity',
    'stats','PluginManager','DebuggerManager','Delay','Spawn','Wait','Version','Stats','ypcall',
}


def _line(node):
    """luau-ast locations look like '112,52 - 112,59' with zero-based lines."""
    return int(node['location'].split(',')[0])+1


def parse(path):
    run=subprocess.run([str(AST_BIN),str(path)],capture_output=True,text=True,encoding='utf-8')
    if run.returncode or not run.stdout.strip():
        raise RuntimeError(f'{path.name}: luau-ast failed: {run.stderr.strip() or run.stdout.strip()}')
    return json.loads(run.stdout)


def _top_level_locals(root):
    declared={}
    for statement in root.get('body',[]):
        kind=statement.get('type')
        if kind=='AstStatLocal':
            for var in statement.get('vars',[]):
                declared.setdefault(var['name'],[]).append(_line(var))
        elif kind=='AstStatLocalFunction':
            name=statement.get('name')
            name=name.get('name') if isinstance(name,dict) else name
            declared.setdefault(name,[]).append(_line(statement))
    return declared


def _globals(node,out):
    if isinstance(node,dict):
        if node.get('type')=='AstExprGlobal':
            out.append((node['global'],_line(node)))
        for value in node.values():
            _globals(value,out)
    elif isinstance(node,list):
        for value in node:
            _globals(value,out)
    return out


def lint(paths):
    findings=[]
    for path in paths:
        path=Path(path)
        root=parse(path)['root']
        declared=_top_level_locals(root)
        for name,line in _globals(root,[]):
            later=[d for d in declared.get(name,[]) if d>line]
            if later:
                findings.append(f"{path.name}: '{name}' used on line {line} before its declaration on line {min(later)}; it is a nil global at runtime")
            elif name not in ALLOWED_GLOBALS:
                findings.append(f"{path.name}: unknown global '{name}' on line {line}")
    return findings


def default_paths():
    return sorted((ROOT/'src').rglob('*.luau'))+sorted((ROOT/'tests').glob('*.luau'))


if __name__=='__main__':
    targets=[Path(a) for a in sys.argv[1:]] or default_paths()
    problems=lint(targets)
    for problem in problems: print(problem)
    print(f'lint_luau: {len(targets)} files, {len(problems)} problems')
    sys.exit(1 if problems else 0)
