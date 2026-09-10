"""Scope lint: a file-level local used before its declaration compiles as a nil global in Luau."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]


def module(name,path):
    spec=importlib.util.spec_from_file_location(name,ROOT/path)
    result=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


class LintLuauTests(unittest.TestCase):
    def lint_source(self,source):
        lint=module('lint_luau','tools/lint_luau.py')
        # Keep even temporary fixture files within the authorized workspace.
        with tempfile.TemporaryDirectory(dir=ROOT/'build') as directory:
            path=Path(directory)/'Fixture.client.luau'
            path.write_text(source,encoding='utf-8')
            return lint.lint([path])

    def test_reports_file_local_used_before_declaration(self):
        findings=self.lint_source(
            'local function render()\n'
            '    actions.Visible=false\n'
            'end\n'
            'local actions=Instance.new("Frame")\n'
        )
        self.assertEqual(len(findings),1)
        self.assertIn("'actions'",findings[0])
        self.assertIn('line 2',findings[0])
        self.assertIn('line 4',findings[0])

    def test_reports_unknown_global(self):
        findings=self.lint_source('local x=RunService.Heartbeat\n')
        self.assertEqual(len(findings),1)
        self.assertIn("'RunService'",findings[0])

    def test_accepts_roblox_globals_and_ordered_locals(self):
        findings=self.lint_source(
            'local RunService=game:GetService("RunService")\n'
            'local actions=Instance.new("Frame")\n'
            'local function render() actions.Visible=false; task.wait(); print(workspace, Enum.Font.Gotham) end\n'
            'render()\n'
        )
        self.assertEqual(findings,[])

    def test_nested_shadowing_is_not_a_forward_reference(self):
        # `id` is a parameter here and a later loop variable there; neither is a file-level local.
        findings=self.lint_source(
            'local function f(id) return id end\n'
            'for _,id in {1,2} do f(id) end\n'
        )
        self.assertEqual(findings,[])


if __name__=='__main__': unittest.main()
