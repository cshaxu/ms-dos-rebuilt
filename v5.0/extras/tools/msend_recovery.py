"""Derive the physical MSEND segment ending from the pinned NTIO source."""
import hashlib

NT_SHA256 = '40d639bb0f09814e537a742081b85557d49c2fc1219f0ff6618d823623f88f0a'
BEGIN = b"sysinitseg      segment para public 'system_init'\r\n"
END = b"dos_load_seg    segment para public 'dos_load_seg'\r\n"
REPLACEMENT = (BEGIN + b'\tassume\tcs:sysinitseg\r\n'
               b'        public  SI_end\r\nSI_end:\r\nsysinitseg     ends\r\n\r\n')

def recover(data):
    if hashlib.sha256(data).hexdigest() != NT_SHA256:
        raise ValueError('unexpected NTIO MSEND reference')
    if data.count(BEGIN) != 1 or data.count(END) != 1:
        raise ValueError('unexpected NTIO segment boundaries')
    start, end = data.index(BEGIN), data.index(END)
    if end <= start:
        raise ValueError('unexpected NTIO segment ordering')
    return data[:start] + REPLACEMENT + data[end:]
