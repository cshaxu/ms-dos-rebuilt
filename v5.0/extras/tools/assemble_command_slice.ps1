$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$stage = Join-Path $root 'build/t2-s1'
$v86 = 'O:\repos.external\OpenNT\base\mvdm\dos\v86'
$assembler = 'O:\repos.hobby\ntvdm64\tools\opennt\tools16\masm.exe'
New-Item -ItemType Directory -Force $stage | Out-Null
Copy-Item -LiteralPath "$v86\cmd\command\tfor.asm" -Destination "$stage\tfor.asm"
Push-Location $root
try {
    & $assembler -Mx -t -W1 "-I$v86\cmd\command" "-I$v86\inc" '-IO:\repos.external\OpenNT\base\mvdm\inc' "-I$v86\messages" 'build\t2-s1\tfor.asm,build\t2-s1\tfor.obj,build\t2-s1\tfor.lst;' 2>&1 | Tee-Object "$stage\assemble.log"
    if ($LASTEXITCODE -ne 0) { throw "MASM failed: $LASTEXITCODE" }
    if (!(Test-Path "$stage\tfor.obj")) { throw 'No object generated' }
    Get-FileHash -Algorithm SHA256 "$stage\tfor.obj"
} finally { Pop-Location }
