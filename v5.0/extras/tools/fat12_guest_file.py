"""Read one regular root file from an owned 512-byte/cluster FAT12 fixture."""
import struct
from pathlib import Path

def read_root_file(image, name):
    b=Path(image).read_bytes()
    bs=struct.unpack_from('<H',b,11)[0]; assert bs==512 and b[13]==1
    reserved=struct.unpack_from('<H',b,14)[0]; fats=b[16]
    spf=struct.unpack_from('<H',b,22)[0]; entries=struct.unpack_from('<H',b,17)[0]
    ro=(reserved+fats*spf)*bs; data=ro+((entries*32+bs-1)//bs)*bs
    stem,ext=name.split('.'); wanted=(stem.ljust(8)+ext.ljust(3)).encode('ascii')
    for off in range(ro,ro+entries*32,32):
        if b[off]==0:return None
        if b[off:off+11]!=wanted:continue
        assert not b[off+11]&0x18
        c=struct.unpack_from('<H',b,off+26)[0];size=struct.unpack_from('<I',b,off+28)[0]
        out=bytearray();seen=set()
        while 2<=c<0xff0:
            assert c not in seen;seen.add(c)
            start=data+(c-2)*bs;assert start+bs<=len(b)
            out.extend(b[start:start+bs]);pos=reserved*bs+c+c//2
            word=int.from_bytes(b[pos:pos+2],'little');c=word>>4 if c&1 else word&0xfff
        assert len(out)>=size
        return bytes(out[:size])
    return None
