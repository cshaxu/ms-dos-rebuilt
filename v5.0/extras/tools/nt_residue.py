"""Lexical leads for NT host dependencies and explicit BOP encodings.

Hits are review candidates, not proof of execution or of non-DOS origin.
This intentionally scans comments and conditional branches as well as code.
"""
import re

PATTERNS = {
    'nt_host': re.compile(rb'(?i)\b(?:NTVDM|NTDOS|NTDOSEM|DOSEMU|DOSWOW|SOFTPC|HRDSVC|SVC_[A-Z0-9_]+|SCS_[A-Z0-9_]+|BOP|VDM)\b'),
    'nt_port': re.compile(rb'(?i)\b(?:ported\s+(?:for|to)\s+NT|Windows\s+NT|NT\s+DOSEm)\b'),
    'nt_include': re.compile(rb'(?i)\b(?:bop|dossvc|dbgsvc|cmdsvc|doswow|vint)\.inc\b'),
    'bop_bytes': re.compile(rb'(?i)\bdb\s+(?:0?c4h|196|0xc4)\s*,\s*(?:0?c4h|196|0xc4)\b'),
    'dos6_specific': re.compile(rb'(?i)\b(?:DBLSPACE(?:_[A-Z0-9_]+)?|DOUBLESPACE|MULTI_CONFIG|MSDOS6|DOS_6)\b'),
}


def scan_bytes(data):
    hits = []
    for number, line in enumerate(data.splitlines(), 1):
        for category, pattern in PATTERNS.items():
            for match in pattern.finditer(line):
                hits.append({'line': number, 'category': category,
                             'match': match.group().decode('ascii', errors='replace')})
    return hits
