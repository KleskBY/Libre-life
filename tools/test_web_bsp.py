import struct
import unittest

from web_bsp import normalize_bsp


def bsp(leaves):
    header = bytearray(8 + 17 * 8)
    struct.pack_into('<4si', header, 0, b'IBSP', 46)
    struct.pack_into('<ii', header, 8 + 4 * 8, len(header), len(leaves) * 48)
    return bytes(header) + b''.join(struct.pack('<12i', *leaf) for leaf in leaves) + b'other lumps unchanged'


class BspCompatibilityTests(unittest.TestCase):
    def test_only_empty_leaf_area_changes(self):
        solid = (-1, -1, -100, -100, -100, 100, 100, 100, 5, 0, 7, 3)
        visible = (0, 1, -100, -100, -100, 100, 100, 100, 5, 2, 7, 3)
        original = bsp([solid, visible])
        result, count = normalize_bsp(original)
        expected = bytearray(original)
        struct.pack_into('<i', expected, 8 + 17 * 8 + 4, 0)
        self.assertEqual(count, 1)
        self.assertEqual(result, bytes(expected))
        self.assertEqual(normalize_bsp(result), (result, 0))

    def test_other_formats_unchanged(self):
        for data in (b'', struct.pack('<i', 29), struct.pack('<i', 30), b'IBSP' + struct.pack('<i', 38)):
            self.assertEqual(normalize_bsp(data), (data, 0))

    def test_nonempty_negative_area_is_rejected(self):
        for cluster, area, faces in ((0, -1, 0), (-1, -1, 1), (-1, -2, 0)):
            with self.assertRaises(ValueError):
                normalize_bsp(bsp([(cluster, area, 0, 0, 0, 0, 0, 0, 0, faces, 0, 0)]))

    def test_malformed_leaf_lump_is_rejected(self):
        for offset, length in ((0, 48), (144, -1), (144, 47), (10000, 48)):
            data = bytearray(bsp([(-1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)]))
            struct.pack_into('<ii', data, 40, offset, length)
            with self.assertRaises(ValueError):
                normalize_bsp(bytes(data))
        with self.assertRaises(ValueError):
            normalize_bsp(b'IBSP' + struct.pack('<i', 46))


if __name__ == '__main__':
    unittest.main()
