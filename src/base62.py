"""
Base-62 encoding/decoding (https://en.wikipedia.org/wiki/Base_62)
"""


class Base62(object):

    def __init__(self, mapping=('0123456789'
                                'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                                'abcdefghijklmnopqrstuvwxyz')):
        if not isinstance(mapping, str) or len(mapping) != 62:
            raise ValueError('mapping must be 62 bytes long')
        self._encoding_table = mapping
        self._decoding_mapping = {}  # '0' -> 0, '1' -> 1 etc.
        for i in range(62):
            self._decoding_mapping[mapping[i]] = i

    def encode(self, number):
        """Convert a non-negative number to base-62 encoded string. Raises
        ValueError if input if not a non-negative integer
        """
        if not isinstance(number, int) or number < 0:
            raise ValueError('invalid input to encode()')
        if number == 0:
            return self._encoding_table[0]

        result = []
        while number > 0:
            number, r = divmod(number, 62)
            result.insert(0, self._encoding_table[r])
        return ''.join(result)

    def decode(self, code):
        """Convert a base-62 encoded string back to integer. Raises
        ValueError if input is not a valid encoded string
        """
        if not isinstance(code, str) or code == '':
            raise ValueError('invalid input to decode()')

        result = 0
        try:
            for c in code:
                n = self._decoding_mapping[c]
                result = result * 62 + n
        except:
            raise ValueError('invalid input to decode()')
        return result
