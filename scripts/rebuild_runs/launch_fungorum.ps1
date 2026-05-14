# Detached launcher for fungorum backbone build.
# Per CLAUDE.md (CRITICAL): use Start-Process so the build survives Claude Code wrapper teardown.

$ErrorActionPreference = "Stop"

$Repo    = "C:\Users\Gilles Colling\Documents\dev\taxify"
$RunDir  = Join-Path $Repo "scripts\rebuild_runs\fungorum"
$Script  = Join-Path $Repo "scripts\rebuild_runs\build_fungorum.R"
$Rscript = "C:\Program Files\R\R-4.6.0\bin\Rscript.exe"

New-Item -ItemType Directory -Force -Path $RunDir | Out-Null

$proc = Start-Process -FilePath $Rscript `
                      -ArgumentList @("--vanilla", "`"$Script`"") `
                      -WorkingDirectory $Repo `
                      -RedirectStandardOutput (Join-Path $RunDir "stdout.log") `
                      -RedirectStandardError  (Join-Path $RunDir "stderr.log") `
                      -WindowStyle Hidden `
                      -PassThru

Set-Content -Path (Join-Path $RunDir "pid.txt") -Value $proc.Id -Encoding utf8
Write-Output "PID=$($proc.Id)"
Write-Output "logs=$RunDir"
