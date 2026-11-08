# M4 T5 S1 baseline audit

S1 is verified and closed; T5 and the complete project remain active.
The admitted requirement was a pinned OpenNT kernel dependency/assembly baseline
and explicit starting strategy, not restored MSDOS.SYS.

- Baseline: m4-t5-kernel-baseline.json pins reference kernel files and link lists
  (OpenNT 38, DOS 6 57, DOS 4 55), with 19 DOS 6-only linked units.
- Dependencies/import: m4-t5-kernel-dependencies.json conservatively resolves
  literal INCLUDEs across conditional branches, 107 files, zero unresolved.
  m4-t5-kernel-import.json records source origins, hashes and preserved local
  files. Kernel resources are kept separate from modified COMMAND messages.
- Build: m4-t5-clean-kernel-build.json proves generation-before-assembly in a
  new stage; 38 objects, four generated message files, tool/source hashes,
  successful isolated tool phases and identical reference SYS/map outputs.
- Difference: m4-t5-reference-comparison.json proves the baseline is not target
  MSDOS.SYS. Reference is 27858 bytes, target 37394; first difference is byte 1.
- Starting strategy: m4-t5-kernel-anchors.json supplies exact unique byte-block
  candidates for mapping. Recover code layout and real DOS paths using the target
  as oracle, OpenNT as primary source and DOS 6/4 as comparative evidence. Do not
  blindly copy all 19 extra modules or equate matching data with recovered code.

Reviewed scripts and actual logs/reports. NOSRVBLD was established from make.inc
after BUILDMSG rejection. LINK 5.10 substitution, no-stack/no-entry warnings,
conservative include closure and remaining host dependencies are documented.
No target kernel execution is inferred. Prior exact COMMAND files were preserved.
Computer Use was not used; DOS tools ran on private desktops with bounded owned
process lifetimes. No publication or deployment occurred.

Transfer to S2: map target entry/segments and initial module correspondence;
derive evidence-backed standalone recovery edits. Lexical host candidates and
byte anchors still require semantic checks. Full kernel byte identity and INT
21h/filesystem tests remain outstanding, as do IO.SYS and integrated deployment.
