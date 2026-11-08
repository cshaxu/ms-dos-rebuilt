"""Check single-config DEVICEHIGH and its SIZE parser against target IO.SYS."""
from pathlib import Path
import hashlib
import json
import re
import struct

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
build = json.loads((evidence / 'm5-bios-singleconfig-probe.json').read_text())
assert build['candidate'] and build['oembase'] and build['singleconfig']
stage = Path(build['stage'])
digest = lambda data: hashlib.sha256(data).hexdigest()
candidate = (stage / 'msbio.bin').read_bytes()
assert digest(candidate) == build['output']['sha256']
image = (root / 'extras/build/target-io-inspect.bin').read_bytes()
assert digest(image) == 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
target = image[0x5a6:]
listing_bytes = (stage / 'sysconf.lst').read_bytes()
map_bytes = (stage / 'msbio.map').read_bytes()
listing = listing_bytes.decode(errors='replace')
map_text = map_bytes.decode(errors='replace')
def local(name):
    rows = re.findall(r'(?im)^' + re.escape(name) + r'\s+(?:\.\s*)+[^\r\n]*?\b([0-9A-F]{4})\s+SYSINITSEG\b', listing)
    assert len(rows) == 1, (name, rows)
    return int(rows[0], 16)
def address(name):
    rows = re.findall(r'(?im)^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+' + re.escape(name) + r'\s*$', map_text)
    values = {int(seg, 16) * 16 + int(off, 16) for seg, off in rows}
    assert len(values) == 1, (name, values)
    return values.pop()
segment = 0x3fd0
module = address('doconf') - segment - local('doconf')
def physical(name):
    return segment + module + local(name)

def check(name, target_start, length, data_refs, calls):
    start = physical(name)
    actual = bytearray(candidate[start:start + length])
    expected = target[target_start:target_start + length]
    assert len(actual) == len(expected) == length
    fixups = []
    for offset, symbol, addend, target_value in data_refs:
        value = int.from_bytes(actual[offset:offset + 2], 'little')
        observed = int.from_bytes(expected[offset:offset + 2], 'little')
        reference = address(symbol) - segment if symbol in {'badblock', 'badsiz_pre', 'crlfm'} else module + local(symbol)
        assert value == reference + addend, (symbol, value)
        assert observed == target_value, (symbol, observed)
        fixups.append({'offset': offset, 'symbol': symbol, 'addend': addend,
                       'candidate': value, 'target': observed})
        actual[offset:offset + 2] = expected[offset:offset + 2]
    for offset, symbol, target_dest, external, opcode in calls:
        assert actual[offset] == expected[offset] == opcode
        dest = start + offset + 3 + struct.unpack_from('<h', actual, offset + 1)[0]
        observed = target_start + offset + 3 + struct.unpack_from('<h', expected, offset + 1)[0]
        assert dest == (address(symbol) if external else physical(symbol)), (symbol, dest)
        assert observed == target_dest, (symbol, observed)
        fixups.append({'offset': offset + 1, 'symbol': symbol,
                       'candidate_destination': dest, 'target_destination': observed})
        actual[offset + 1:offset + 3] = expected[offset + 1:offset + 3]
    assert actual == expected, name
    return {'candidate_offset': start, 'target_offset': target_start, 'length': length,
            'fixups': fixups, 'normalized_equal': True}

entry = check('tryu', 0x6382, 0x4f,
              [(0x08, 'badparm_off', 0, 0x165d), (0x0d, 'badparm_seg', 0, 0x165f),
               (0x31, 'DevSavedDelim', 0, 0x215d), (0x3c, 'DeviceHi', 0, 0x2148),
               (0x42, 'DevUMB', 0, 0x2139), (0x4a, 'DeviceHi', 0, 0x2148)],
              [(0x0f, 'ParseSize', 0x6d2a, False, 0xe8), (0x14, 'badparm_p', 0x69f8, False, 0xe8),
               (0x27, 'delim', 0x7420, True, 0xe8)])
size = check('ParseSize', 0x6d2a, 0x3f,
             [(0x03, 'DevSizeOption', 0, 0x2149), (0x0a, 'DevCmdLine', 0, 0x2159),
              (0x0f, 'DevCmdLine', 2, 0x215b), (0x36, 'DevSizeOption', 0, 0x2149)],
             [(0x11, 'SkipDelim', 0x6d69, False, 0xe8), (0x27, 'delim', 0x7420, True, 0xe8),
              (0x2f, 'GetHexNum', 0x6d75, False, 0xe8), (0x38, 'SkipDelim', 0x6d69, False, 0xe8)])
load = check('tryd', 0x63d1, 0x6f,
             [(0x0b, 'DeviceHi', 0, 0x2148), (0x11, 'DevSizeOption', 0, 0x2149),
              (0x18, 'DevSavedDelim', 0, 0x215d), (0x2c, 'DevCmdLine', 0, 0x2159),
              (0x31, 'DevCmdLine', 2, 0x215b), (0x40, 'DevLoadAddr', 0, 0x212d),
              (0x45, 'DevSize', 0, 0x212b), (0x4c, 'DevLoadEnd', 0, 0x212f)],
             [(0x05, 'tryq', 0x6633, False, 0xe9), (0x33, 'round', 0x7463, True, 0xe8),
              (0x36, 'SizeDevice', 0x6c32, False, 0xe8), (0x3b, 'InitDevLoad', 0x6b2f, False, 0xe8),
              (0x50, 'mem_err', 0x74a5, True, 0xe9), (0x59, 'badop', 0x69ec, False, 0xe9),
              (0x5c, 'badload', 0x7705, True, 0xe8), (0x66, 'ExecDev', 0x6c81, False, 0xe8)])
init = check('goodld', 0x6440, 0x87,
             [(0x0e, 'DevEntry', 0, 0x2131), (0x42, 'DevLoadEnd', 0, 0x212f),
              (0x5e, 'DevBrkAddr', 0, 0x2135), (0x66, 'DevBrkAddr', 2, 0x2137),
              (0x6b, 'DevUMB', 0, 0x2139)],
             [(0x02, 'RemoveNull', 0x6c9e, False, 0xe8),
              (0x2a, 'LieInt12Mem', 0x6ab0, False, 0xe8),
              (0x2d, 'UpdatePDB', 0x6b1d, False, 0xe8),
              (0x4c, 'calldev', 0x74b0, True, 0xe8),
              (0x52, 'calldev', 0x74b0, True, 0xe8),
              (0x55, 'TrueInt12Mem', 0x6ae7, False, 0xe8),
              (0x70, 'AllocUMB', 0x6dda, False, 0xe8),
              (0x7b, 'TryToMovDOSHi', 0x48fa, True, 0xe8)])
for offset, symbol, target_dest in [(0x26, 'badnumblock', 0x64c7),
                                     (0x85, 'was_device_com', 0x64e8)]:
    start = init['candidate_offset']
    assert start + offset + 2 + struct.unpack_from('<b', candidate, start + offset + 1)[0] == physical(symbol)
    assert 0x6440 + offset + 2 + struct.unpack_from('<b', target, 0x6440 + offset + 1)[0] == target_dest
post = check('badnumblock', 0x64c7, 0x16c,
             [(0x03, 'badblock', 0, 0x3c68), (0x23, 'DevBrkAddr', 2, 0x2137),
              (0x28, 'DevLoadEnd', 0, 0x212f), (0x34, 'DevEntry', 0, 0x2131),
              (0xbe, 'DevBrkAddr', 0, 0x2135), (0xc6, 'DevBrkAddr', 2, 0x2137),
              (0xcf, 'DevBrkAddr', 0, 0x2135), (0xd4, 'DevBrkAddr', 0, 0x2135),
              (0x107, 'DevEntry', 0, 0x2131), (0x12d, 'DevEntry', 0, 0x2131),
              (0x13b, 'DevEntry', 0, 0x2131), (0x161, 'badsiz_pre', 0, 0x3b8a),
              (0x164, 'crlfm', 0, 0x3b68)],
             [(0x05, 'print', 0x772f, True, 0xe8), (0x14, 'error_line', 0x6a4a, False, 0xe8),
              (0x4b, 'DevSetBreak', 0x6cd3, False, 0xe8),
              (0x93, 'DevSetBreak', 0x6cd3, False, 0xe8),
              (0xd7, 'RoundBreakAddr', 0x6cb1, False, 0xe8),
              (0x11a, 'tempcds', 0x4c05, True, 0xe8),
              (0x14c, 'DevBreak', 0x6cf8, False, 0xe8),
              (0x158, 'DevBreak', 0x6cf8, False, 0xe8),
              (0x166, 'prnerr', 0x770b, True, 0xe8)])
umb = check('InitDevLoad', 0x6b2f, 0x103,
            [(0x03, 'DeviceHi', 0, 0x2148), (0x17, 'DevUMBFree', 0, 0x213e),
             (0x1c, 'DevUMBAddr', 0, 0x213a), (0x21, 'DevUMBSize', 0, 0x213c),
             (0x28, 'DeviceHi', 0, 0x2148), (0x39, 'DevLoadAddr', 0, 0x212d),
             (0x3e, 'DevLoadEnd', 0, 0x212f), (0x43, 'DevEntry', 0, 0x2131),
             (0x49, 'DevEntry', 2, 0x2133), (0x4e, 'DevUMBSize', 0, 0x213c),
             (0x53, 'DevUMBAddr', 0, 0x213a), (0x58, 'DevUMBFree', 0, 0x213e),
             (0x64, 'DevSize', 0, 0x212b), (0x77, 'DevSize', 0, 0x212b),
             (0x98, 'DevUMBSize', 0, 0x213c), (0x9c, 'DevUMBAddr', 0, 0x213a),
             (0xa0, 'DevUMBFree', 0, 0x213e), (0xa8, 'DevUMBSize', 0, 0x213c),
             (0xac, 'DevUMBAddr', 0, 0x213a), (0xb0, 'DevUMBFree', 0, 0x213e)],
            [(0x08, 'SpaceInUMB?', 0x6b7b, False, 0xe8),
             (0x0d, 'ShrinkUMB', 0x6fc9, False, 0xe8),
             (0x10, 'GetUMBForDev', 0x6b96, False, 0xe8),
             (0x34, 'DevSetMark', 0x6be3, False, 0xe8)])
# Validate branches leaving the checked entry, in both binaries.
for offset, symbol, target_dest in [(3, 'tryd', 0x63d1), (0x45, 'LoadDevice', 0x63ec),
                                     (0x4d, 'LoadDevice', 0x63ec)]:
    start = entry['candidate_offset']
    assert start + offset + 2 + struct.unpack_from('<b', candidate, start + offset + 1)[0] == physical(symbol)
    assert 0x6382 + offset + 2 + struct.unpack_from('<b', target, 0x6382 + offset + 1)[0] == target_dest
report = {'stage': str(stage), 'candidate_sha256': digest(candidate), 'target_bios_sha256': digest(target),
          'map_sha256': digest(map_bytes), 'listing_sha256': digest(listing_bytes),
          'entry': entry, 'size_parser': size, 'load_prelude': load, 'driver_init': init, 'device_link_and_dpb': post, 'umb_allocation_and_mark': umb,
          'scope': 'Linked DEVICEHIGH entry, ParseSize, DEVICE load prelude, driver init, device linking, DPB construction and UMB allocation; named address normalization is comparison-only. No complete driver loading or runtime claim.'}
(evidence / 'm5-bios-devicehigh-verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
