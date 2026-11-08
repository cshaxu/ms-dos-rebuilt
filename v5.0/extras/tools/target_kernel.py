"""Read the owner's retained and hash-verified target kernel."""
from target_files import BASELINE, read_target as read_file

def read_target(root):
    return read_file('MSDOS.SYS'), str(BASELINE / 'MSDOS.SYS')
