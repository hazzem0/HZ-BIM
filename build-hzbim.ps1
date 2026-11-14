# HZ-BIM one-click build
# Lives in the root of the HZ-BIM repo. Gets/updates the code from github.com/hazzem0/HZ-BIM, builds the MCP server,
# the Revit plugin for every installed Revit year and the Navisworks plugin for every
# installed Navisworks Manage year. Everything is written to build-log.txt next to this script.
# Nothing is installed into Revit/Navisworks - this only builds.

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = $root
$log  = Join-Path $root 'build-log.txt'
Set-Content -Path $log -Value "HZ-BIM build log  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Encoding UTF8

function Log($msg) { Write-Host $msg; Add-Content -Path $log -Value $msg -Encoding UTF8 }
function Run($title, $exe, [string[]]$argList, $cwd) {
    Log ""; Log "==== $title ===="; Log "> $exe $($argList -join ' ')"
    Push-Location $cwd
    $out = & $exe @argList 2>&1 | Out-String
    $code = $LASTEXITCODE
    Pop-Location
    Add-Content -Path $log -Value $out -Encoding UTF8
    if ($code -eq 0) { Log "RESULT: OK" } else { Log "RESULT: FAILED (exit $code)" }
    return $code
}

# ---- Tools check ----
Log ""; Log "==== Tools ===="
foreach ($t in 'git','dotnet','node','npm') {
    $c = Get-Command $t -ErrorAction SilentlyContinue
    if ($c) { Log "$t : $($c.Source)" } else { Log "$t : NOT FOUND" }
}
if (Get-Command dotnet -ErrorAction SilentlyContinue) { Log (dotnet --list-sdks | Out-String) }

# ---- Get the code ----
# Offline option: if the code zip sits next to this script, unpack it (no GitHub needed).
$zip = Join-Path $repo 'HZ-BIM-src.zip'
if ((Test-Path $zip) -and -not (Test-Path (Join-Path $repo 'revit-mcp-server'))) {
    Log ""; Log "==== Unpacking HZ-BIM-src.zip ===="
    Expand-Archive -Path $zip -DestinationPath $repo -Force
    Log "RESULT: OK"
}
$hasCode = Test-Path (Join-Path $repo 'revit-mcp-server')
$hasCommits = $false
if (Test-Path (Join-Path $repo '.git')) { git -C $repo rev-parse --verify HEAD 2>$null | Out-Null; $hasCommits = ($LASTEXITCODE -eq 0) }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Log "git is missing - install Git for Windows from https://git-scm.com"
} elseif ($hasCommits) {
    Run 'git pull' 'git' @('pull','--ff-only') $repo | Out-Null
} elseif (-not $hasCode) {
    # First run: this folder only has the build scripts - turn it into a clone of the repo.
    if (-not (Test-Path (Join-Path $repo '.git'))) { Run 'git init' 'git' @('init','-b','main') $repo | Out-Null }
    git -C $repo remote get-url origin 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Run 'git remote' 'git' @('remote','add','origin','https://github.com/hazzem0/HZ-BIM') $repo | Out-Null }
    Run 'git fetch' 'git' @('fetch','origin') $repo | Out-Null
    Run 'git checkout' 'git' @('checkout','-f','-B','main','--track','origin/main') $repo | Out-Null
} else {
    Log ""; Log "Code is already in this folder (copied in) - skipping git, building what is here."
}
if (-not (Test-Path (Join-Path $repo 'revit-mcp-server'))) {
    Log "The code is not in this folder (GitHub could not be reached). Stopping."
    Read-Host 'Press Enter to close'; exit 1
}
if ($hasCommits) { Log "Commit: $(git -C $repo log -1 --format='%h %s')" }

# ---- Installed Autodesk versions ----
$revitYears = @(2020..2027 | Where-Object { Test-Path "C:\Program Files\Autodesk\Revit $_\Revit.exe" })
$navisYears = @(2020..2027 | Where-Object { Test-Path "C:\Program Files\Autodesk\Navisworks Manage $_\Roamer.exe" })
Log ""; Log "Revit installed: $($revitYears -join ', ')"
Log "Navisworks Manage installed: $($navisYears -join ', ')"
if ($revitYears.Count -eq 0) { $revitYears = @(2026); Log "No Revit found - building 2026 as a compile test." }
if ($navisYears.Count -eq 0) { $navisYears = @(2024); Log "No Navisworks found - building 2024 as a compile test." }

$summary = @()

# ---- MCP server ----
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $srv = Join-Path $repo 'revit-mcp-server'
    $a = Run 'MCP server: npm ci' 'npm.cmd' @('ci','--no-audit','--no-fund') $srv
    $b = Run 'MCP server: npm run build' 'npm.cmd' @('run','build') $srv
    $summary += "MCP server: " + $(if ($a -eq 0 -and $b -eq 0) {'OK'} else {'FAILED'})
}

# ---- Revit plugin ----
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    $rp = Join-Path $repo 'revit-mcp-plugin\HzBimPlugin\HzBimPlugin.csproj'
    foreach ($y in $revitYears) {
        $c = Run "Revit plugin $y" 'dotnet' @('build',$rp,'-c','Release',"-p:RevitVersion=$y",'--nologo','-v','minimal') $root
        $summary += "Revit $y : " + $(if ($c -eq 0) {'OK'} else {'FAILED'})
    }
    $np = Join-Path $repo 'navis-mcp-plugin\HzBimNavisPlugin\HzBimNavisPlugin.csproj'
    foreach ($y in $navisYears) {
        $c = Run "Navisworks plugin $y" 'dotnet' @('build',$np,'-c','Release',"-p:NavisYear=$y",'--nologo','-v','minimal') $root
        $summary += "Navisworks $y : " + $(if ($c -eq 0) {'OK'} else {'FAILED'})
    }
} else {
    Log "dotnet SDK is missing - install .NET 8 SDK from https://dotnet.microsoft.com/download and run again."
}

Log ""; Log "==== SUMMARY ===="; $summary | ForEach-Object { Log $_ }
Log ""; Log "Done. Tell Claude: 'build done'."
Read-Host 'Press Enter to close'
