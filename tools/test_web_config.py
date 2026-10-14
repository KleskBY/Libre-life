import unittest
from web_config import ROOT, clean_aliases, web_config

HAS_QUALKER = (ROOT / 'web' / 'qualker' / 'web.cfg').is_file()  # downstream gamedir, absent from public clones


class WebConfigTests(unittest.TestCase):
    def test_old_impulse_aliases_do_not_shadow_qc_commands(self):
        aliases = (b'alias "flashlight" "impulse 14"\n'
                   b'alias inventory "impulse 16"\n'
                   b'alias "reload" "impulse 100"\n'
                   b'alias "+duck" "+button3"\n')
        self.assertEqual(clean_aliases(aliases),
                         b'alias "reload" "impulse 100"\nalias "+duck" "+button3"\n')

    def test_all_profiles_disable_hitmodel(self):
        profiles = [('librelife', False), ('librelife', True)] + [('qualker', True)] * HAS_QUALKER
        for game, lite in profiles:
            self.assertIn(b'\nset sv_hitmodel 0\n', web_config(game, lite).replace(b'\r\n', b'\n'))
            self.assertIn(b'bind f "cmd flashlight"', web_config(game, lite))

    @unittest.skipUnless(HAS_QUALKER, 'web/qualker is not present')
    def test_qualker_inventory_and_existing_controls(self):
        config = web_config('qualker', True)
        for binding in (b'bind i "inventory"', b'bind b "inventory"',
                        b'bind g "drop"', b'bind c "+button3"', b'bind p "togglemenu"'):
            self.assertIn(binding, config)


if __name__ == '__main__':
    unittest.main()
