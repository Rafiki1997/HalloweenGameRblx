"""docs/ASSETS.md is generated from the manifest so reported counts cannot drift from the build."""
import importlib.util
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]


def module(name,path):
    spec=importlib.util.spec_from_file_location(name,ROOT/path)
    result=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


class AssetsDocTests(unittest.TestCase):
    def test_one_row_per_asset_with_status(self):
        generator=module('gen_assets_doc','tools/gen_assets_doc.py')
        manifest={'assets':{
            'Lamp':{'zone':'Props','footprint':[1.2,8.6,1.1],'roles':['Glow','Metal'],'triangleBudget':300,'triangles':252,'meshCount':3,'assetId':1234567,'uploadedAt':'2026-09-09T00:00:00+00:00'},
            'Arch':{'zone':'Plaza','footprint':[16.2,16.3,16.2],'roles':['Stone'],'triangleBudget':2500,'triangles':564,'meshCount':4,'assetId':0,'uploadedAt':None},
        }}
        text=generator.generate(manifest)
        rows={line.split('|')[1].strip():line for line in text.splitlines() if line.startswith('| ') and line.split('|')[1].strip() not in ('Asset','---')}
        self.assertEqual(set(rows),{'Lamp','Arch'})
        self.assertIn('uploaded 1234567',rows['Lamp']); self.assertIn('252 / 300',rows['Lamp'])
        self.assertIn('not uploaded',rows['Arch']); self.assertIn('Plaza',rows['Arch'])
        self.assertIn('2 assets, 1 uploaded',text)


if __name__=='__main__': unittest.main()
