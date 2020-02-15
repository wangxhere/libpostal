from geodata3.encoding import safe_encode, safe_decode
from geodata3.text import _tokenize
from geodata3.text.token_types import token_types



def tokenize(s, whitespace=False):
    u = safe_decode(s)
    s = safe_encode(s)
    return [(safe_decode(s[start:start + length]), token_types.from_id(token_type))
            for start, length, token_type in _tokenize.tokenize(u, whitespace)]
