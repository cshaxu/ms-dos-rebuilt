"""Known comment-only changes since the retained COMMAND exact build."""
CHANGES = {
    'tcode': [
        (b'        CLI     ; DOS5 reconstruction: target COMMAND entry uses FA', b'        CLI'),
        (b'        STI     ; DOS5 reconstruction: target COMMAND entry uses FB', b'        STI'),
        (b'; DOS5 reconstruction: no NT EXECPATH_SIZE reset at this entry.\r\n', b''),
        (b'; DOS5 reconstruction: target 24C6..24E4; DOS6 corroborates input path.\r\n', b''),
        (b'; DOS5 reconstruction: NT host reentry/prompt/TSR helpers removed.\r\n', b''),
    ],
    'init': [(b'; DOS 5 local AUTOEXEC path, corroborated by target and DOS 6.\r\n', b'')],
}

def apply_changes(name, data):
    for old, new in CHANGES.get(name.lower(), []):
        if data.count(old) != 1:
            raise ValueError(f'expected one occurrence in {name}: {old!r}')
        data = data.replace(old, new, 1)
    return data
