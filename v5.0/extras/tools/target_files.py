"""Read the owner's retained system-file baseline without mounting media."""
from pathlib import Path
import hashlib

BASELINE = Path(r'O:\DOS')
TARGETS = {
    'IO.SYS': (33430, 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'),
    'MSDOS.SYS': (37394, '4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'),
    'COMMAND.COM': (47845, '74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89'),
}

def read_target(name):
    length, expected = TARGETS[name]
    path = BASELINE / name
    data = path.read_bytes()
    if len(data) != length or hashlib.sha256(data).hexdigest() != expected:
        raise ValueError(f'{path}: retained baseline size/hash mismatch')
    return data
