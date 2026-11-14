# M5 T10 completion audit

Status: closed. S1 covers v5.0, v6.2, v6.21 and v6.22 build visibility.
Owner requested observable activity instead of long silent builds.

Four tooling files changed per version: CMD helper, DOS batch, native C
launcher, and host hash pins. No DOS source, makefile, compiler flag, link
order, source manifest, target or published asset changed.

Completion evidence is build-progress-acceptance.json under each extras/docs/etc.
The unchanged compiler-input counts are 242, 225, 227 and 231 respectively;
overlay versions count baseline files and local overlay files separately.
Removing only new status-echo lines from each DOS batch reproduces its prior
text exactly. No full DOS rebuild was needed.

Native fixture testing observed flushed phase output at 5 and 10 seconds,
identical console and host.log text, private desktop execution and preservation
of a child exit code of 7. A stale cached launcher was replaced through the
actual CMD rebuild branch and matched the new pinned executable hash.
All four CMD fixture runs emitted the 25-file counter and retained incorrect
hash/output rejection and publication rollback. Published files still compare
exactly to their original targets. Native isolation and timeout policy remain.

The console now reports six stages, hash activity every 25 operations, current
DOS phase every five seconds, and precise failure log paths. These indicators
are activity and stage information, not fabricated percentage completion.
Detailed compiler output remains in the existing logs. No non-CMD/BAT/C tool
was introduced, no desktop UI automation was used, and no in-scope transfer
remains. No Git commit or archive was created.
