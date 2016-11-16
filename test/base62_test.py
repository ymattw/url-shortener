import sys
import unittest

sys.path.insert(0, 'src')
from base62 import Base62  # nopep8


class Base62Test(unittest.TestCase):

    def test_init(self):
        self.assertRaises(ValueError, Base62, 'abc')
        self.assertRaises(ValueError, Base62, 123)

    def test_encode_normal(self):
        tests = (
            (0, '0'),
            (10, 'A'),
            (61, 'z'),
            (62, '10'),
            (19158, '4z0'),
        )

        for n, c in tests:
            self.assertEquals(Base62().encode(n), c)

    def test_encode_neg(self):
        tests = [-1, '', '123', '-123']
        for n in tests:
            self.assertRaises(ValueError, Base62().encode, n)

    def test_decode_normal(self):
        tests = (
            (0, '0'),
            (10, 'A'),
            (61, 'z'),
            (62, '10'),
            (19158, '4z0'),
        )

        for n, c in tests:
            self.assertEquals(Base62().decode(c), n)

    def test_decode_neg(self):
        tests = [-1, '', '!123', '-123']
        for c in tests:
            self.assertRaises(ValueError, Base62().decode, c)


if __name__ == '__main__':
    unittest.main()
