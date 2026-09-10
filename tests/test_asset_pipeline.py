"""Metadata and nested-packaging checks; no Blender or Roblox credentials needed."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]


def module(name,path):
    spec=importlib.util.spec_from_file_location(name,ROOT/path)
    result=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


class AssetPipelineTests(unittest.TestCase):
    def test_id_and_footprint_are_preserved(self):
        generator=module('gen_ids','tools/gen_asset_ids.py')
        manifest={'assets':{'Lamp':{'assetId':1234567890123,'footprint':[2,8,2],'roles':['Metal','Glow']}}}
        generated=generator.generate(manifest)
        self.assertIn('Id=1234567890123',generated)
        self.assertIn('Footprint=Vector3.new(2, 8, 2)',generated)
        self.assertIn('Roles={"Metal", "Glow"}',generated)
        for bad in (-1,True,'123',2**53):
            manifest['assets']['Lamp']['assetId']=bad
            with self.assertRaises(ValueError): generator.generate(manifest)

    def test_nested_loader_is_packaged_as_a_module(self):
        packager=module('packager','tools/build_place.py')
        # Keep even temporary fixture files within the authorized workspace.
        with tempfile.TemporaryDirectory(dir=ROOT/'build') as directory:
            folder=Path(directory)
            (folder/'Assets').mkdir()
            source='return { place = function() return "fixture" end }\n'
            (folder/'Assets/Loader.luau').write_text(source,encoding='utf-8')
            root=ET.Element('Item')
            packager.sources(root,folder)
            nested=root.find("./Item[@class='Folder']")
            self.assertEqual(nested.find("./Properties/string[@name='Name']").text,'Assets')
            loader=nested.find("./Item[@class='ModuleScript']")
            self.assertEqual(loader.find("./Properties/string[@name='Name']").text,'Loader')
            self.assertEqual(loader.find("./Properties/ProtectedString[@name='Source']").text,source)


if __name__=='__main__': unittest.main()
