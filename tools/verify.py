"""Compile every script, run rules, and check packaged sources match their files."""
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET
import sys

ROOT = Path(__file__).resolve().parents[1]
BIN = ROOT / '.tools/luau'
failures = []
import importlib.util
spec = importlib.util.spec_from_file_location('lint_luau', ROOT / 'tools/lint_luau.py')
lint = importlib.util.module_from_spec(spec); spec.loader.exec_module(lint)
problems = lint.lint(lint.default_paths())
for problem in problems:
    print(problem)
if problems:
    failures.append('scope lint')
for path in sorted((ROOT / 'src').rglob('*.luau')):
    run = subprocess.run([str(BIN / 'luau-compile.exe'), str(path), '--null'], capture_output=True, text=True)
    if run.returncode:
        failures.append(str(path))
        print(run.stdout, run.stderr)
for path in sorted((ROOT / 'tests').glob('RuntimeAcceptance*.luau')):
    run = subprocess.run([str(BIN / 'luau-compile.exe'), str(path), '--null'], capture_output=True, text=True)
    if run.returncode:
        failures.append(str(path))
        print(run.stdout, run.stderr)
for path in sorted((ROOT / 'tests').glob('*.spec.luau')):
    run = subprocess.run([str(BIN / 'luau.exe'), path.relative_to(ROOT).as_posix()], cwd=ROOT)
    if run.returncode:
        failures.append(path.name)
tree = ET.parse(ROOT / 'build/GhostlightHollow.rbxlx')
packed = [node.text for node in tree.findall('.//ProtectedString[@name="Source"]')]
paths = list((ROOT / 'src').rglob('*.luau'))
for path in paths:
    if path.read_text(encoding='utf-8') not in packed:
        failures.append(f'packaged source mismatch: {path}')
if len(packed) != len(paths):
    failures.append('script count mismatch')
if any('RuntimeTestStatus' in source for source in packed):
    failures.append('test-only control leaked into production')
if failures:
    print('FAILED:', failures)
    sys.exit(1)
print(f'PASS: {len(paths)} Luau scripts compile, scope lint clean; packaged sources match exactly.')
