import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('catalogue_tool',ROOT/'tools/catalogue_tool.py')
tool=importlib.util.module_from_spec(spec);spec.loader.exec_module(tool)

class ValidationTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name);self.script=self.root/'script';self.script.mkdir()
  self.manifest=dict(id='creator.test',name='Test',author='Test author',game='Any',api='1.2',permissions=['ui'])
  self.write();(self.script/'main.lua').write_text('error("VALIDATION MUST NEVER EXECUTE THIS")',encoding='utf-8')
 def tearDown(self):self.temp.cleanup()
 def write(self): (self.script/'script.json').write_text(json.dumps(self.manifest),encoding='utf-8')
 def reject(self):
  self.write()
  with self.assertRaises(ValueError):tool.validate_script(self.script)
 def test_all_api_versions(self):
  for api in ['1.0','1.1','1.2']:
   with self.subTest(api=api):self.manifest['api']=api;self.write();tool.validate_script(self.script)
 def test_full_current_permission_allowlist(self):
  self.manifest['permissions']=sorted(tool.PERMISSIONS);self.write();tool.validate_script(self.script)
  self.assertEqual(len(tool.PERMISSIONS),15)
 def test_unknown_permission(self):self.manifest['permissions']=['ui','native.execute'];self.reject()
 def test_duplicate_permission(self):self.manifest['permissions']=['ui','ui'];self.reject()
 def test_excessive_permissions(self):self.manifest['permissions']=['ui']*16;self.reject()
 def test_unknown_api(self):self.manifest['api']='9.9';self.reject()
 def test_unknown_game(self):self.manifest['game']='Other';self.reject()
 def test_duplicate_json_key(self):
  (self.script/'script.json').write_text('{"id":"creator.test","id":"creator.other"}',encoding='utf-8')
  with self.assertRaises(ValueError):tool.validate_script(self.script)
 def test_binary_file_rejected(self):
  (self.script/'payload.exe').write_bytes(b'MZ')
  with self.assertRaises(ValueError):tool.validate_script(self.script)
 def test_bytecode_rejected(self):
  (self.script/'main.lua').write_bytes(b'\x1bLJ\0')
  with self.assertRaises(ValueError):tool.validate_script(self.script)
 def test_oversized_main_rejected(self):
  (self.script/'main.lua').write_bytes(b'-'*65537)
  with self.assertRaises(ValueError):tool.validate_script(self.script)
 def test_unsafe_id_rejected(self):self.manifest['id']='../outside';self.reject()
 def test_gameplay_package_without_execution(self):
  self.manifest['permissions']=['ui','game.read','entities.read','actions.teleport'];self.write()
  archive,proposal=tool.package(self.script,'Slyrith/Yuri-Lua','test-only',self.root/'dist')
  with zipfile.ZipFile(archive)as z:self.assertEqual(set(z.namelist()),{'main.lua','script.json'})
  self.assertEqual(len(tool.validate_catalogue(proposal)['scripts']),1)
 def test_output_must_not_be_script_folder(self):
  with self.assertRaises(ValueError):tool.package(self.script,'Slyrith/Yuri-Lua','test',self.script/'dist')
 def test_unsafe_downloads_rejected(self):
  for url in ['http://github.com/a/b/releases/download/t/f.zip','https://github.com.evil.test/a/b/releases/download/t/f.zip','https://github.com/a/b/raw/main/f.zip','https://github.com/a/b/releases/download/t/f.zip?token=private']:
   with self.subTest(url=url):self.assertFalse(tool.valid_download(url))
 def test_overlay_validation_preserves_catalogue(self):
  examples=self.root/'examples';examples.mkdir();self.script.rename(examples/'test')
  self.assertEqual(tool.validate(self.root,examples_only=True),(0,1))
  self.assertFalse((self.root/'catalogue.json').exists())
  with self.assertRaises(FileNotFoundError):tool.validate(self.root)

if __name__=='__main__':unittest.main()
