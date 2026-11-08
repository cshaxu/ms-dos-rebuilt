"""Require the pinned COMMAND.COM content after recording build evidence."""
import hashlib

TARGET_LENGTH = 47845
TARGET_SHA256 = '74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89'

def require_target(data):
    if len(data) != TARGET_LENGTH or hashlib.sha256(data).hexdigest() != TARGET_SHA256:
        raise ValueError('COMMAND.COM does not match the pinned target extract')
