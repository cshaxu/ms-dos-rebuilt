# COMMAND source style adjustment

The owner's requested Microsoft-style source presentation led to six
comment-only edits after the retained exact COMMAND build. The bounded edits
are specified as byte replacements in `tools/command_style_changes.py` and
checked against all 34 retained build inputs by
`tools/verify_command_local_inputs.py`. The retained build object hashes and
four staged assets are checked as well. The new source has not been assembled.

The removed recovery notes recorded the following investigation context:

- `TCODE.ASM` uses CLI and STI at the transient entry; the retained target
  comparison identified their FA and FB encodings.
- The NT `EXECPATH_SIZE` reset is absent at that entry, and NT host
  reentry/prompt/TSR helpers were removed in the candidate.
- The `REGCOM` input path was compared with target offsets 24C6h–24E4h and
  DOS 6 source.
- The local AUTOEXEC path in `INIT.ASM` was compared with the target and DOS 6.

These notes document the rationale of earlier recovery work; they are not
independent verification of all referenced behavior. They are retained here
instead of appearing as modern archaeology commentary in the historical
assembly. No original authorship is asserted.
