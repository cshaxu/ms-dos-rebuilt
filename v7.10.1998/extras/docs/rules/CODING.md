# Coding rules

## Owner reference restriction

For v7.10.1998 reconstruction, use only the frozen v7.10.1111 source baseline and the frozen v7.10.1998 target image. The inherited 1111 toolchain is used to build the source.

Adapted from SoftPC `docs/rules/CODING.md` for historical assembly. Keep provenance and source-to-binary mapping visible; preserve relevant syntax, macros, conditional branches, segment structure and link order until evidence justifies a change. Record reconstruction and toolchain assumptions. Do not conceal mismatches through opaque binary substitution. Separate source, generated output and test inputs. Verify behavior and binary differences at the affected scope; retain unresolved deviations in evidence or TODO. Avoid imposing SoftPC C17 or x86/x64 host-build rules on 16-bit DOS.

Owner requirement: restored source should follow the original Microsoft module structure, assembly formatting, procedure comments and parameter/register conventions as consistently as possible. Preserve original names, macro usage and calling conventions where target evidence permits. Keep reconstruction rationale, temporary layout departures and provenance in evidence documents; source comments should use the surrounding historical style. Do not fabricate original authorship or copyright notices.
