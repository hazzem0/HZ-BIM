# HZ-BIM: build the real Setup wizard (HZ-BIM-Setup.exe) - logo, version checkboxes, uninstaller.
# Uses installer\setup.iss (Inno Setup).
# Builds every Revit (2020-2027) and Navisworks (2020-2027) version, so the wizard can offer all of them.
# Log: installer-log.txt next to this script.

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$log  = Join-Path $root 'installer-log.txt'
Set-Content -Path $log -Value "HZ-BIM installer build  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Encoding UTF8
function Log($msg) { Write-Host $msg; Add-Content -Path $log -Value $msg -Encoding UTF8 }
function Run($title, $exe, [string[]]$argList, $cwd) {
    Log ""; Log "==== $title ===="
    Push-Location $cwd
    $out = & $exe @argList 2>&1 | Out-String
    $code = $LASTEXITCODE
    Pop-Location
    Add-Content -Path $log -Value $out -Encoding UTF8
    if ($code -eq 0) { Log "RESULT: OK" } else { Log "RESULT: FAILED (exit $code)" }
    return $code
}
function Fail($msg) { Log ""; Log "STOPPED: $msg"; Read-Host 'Press Enter to close'; exit 1 }

# ---- 0. Remove leftovers from older copies of the source ----
$stale = @(
    'CHANGES-HZ-BIM.md', 'revit-mcp-plugin\HzBimPlugin\PowerBI\Assets\bimBot3DViewer1A2B3C4D.pbiviz',
    'CLAUDE.md', '.graphifyignore', 'common-coding-errors.md', 'deploy.ps1', 'website.md', 'SETUP_ANTIGRAVITY.md',
    'hz-bim-product-maintainer', 'docs', 'HZ-BIM-src.zip', 'build-log.txt', 'deploy-log.txt', 'claude-config-log.txt'
)
foreach ($old in $stale) {
    $f = Join-Path $root $old
    if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue; Log "Removed: $old" }
}
# An empty .git left by a failed first clone (no commits) is useless - remove it. A real clone is kept.
$gitDir = Join-Path $root '.git'
if (Test-Path $gitDir) {
    git -C $root rev-parse --verify HEAD 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Remove-Item $gitDir -Recurse -Force -ErrorAction SilentlyContinue; Log "Removed: empty .git" }
}

# ---- 1. Inno Setup (the wizard compiler) ----
$isccPaths = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "C:\Program Files (x86)\Inno Setup 6\ISCC.exe", "C:\Program Files\Inno Setup 6\ISCC.exe")
$iscc = $isccPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) {
    Log "Inno Setup not found - installing it with winget..."
    Run 'winget install Inno Setup' 'winget' @('install','--id','JRSoftware.InnoSetup','-e','--silent','--accept-package-agreements','--accept-source-agreements') $root | Out-Null
    $iscc = $isccPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $iscc) { Fail "Install Inno Setup 6 from https://jrsoftware.org/isdl.php then run this again." }
}
Log "Inno Setup: $iscc"

# ---- 2. Portable Node.js for the installer (copied from the system Node) ----
$bundled = Join-Path $root 'installer\nodejs\node.exe'
if (-not (Test-Path $bundled)) {
    $sys = (Get-Command node -ErrorAction SilentlyContinue).Source
    if (-not $sys) { Fail "Node.js is not installed." }
    Copy-Item $sys $bundled -Force
    Log "Bundled node.exe copied from $sys"
}

# ---- 3. MCP server ----
$srv = Join-Path $root 'revit-mcp-server'
if ((Run 'MCP server: npm ci' 'npm.cmd' @('ci','--no-audit','--no-fund') $srv) -ne 0) { Fail "npm ci failed (see log)." }
if ((Run 'MCP server: build' 'npm.cmd' @('run','build') $srv) -ne 0) { Fail "MCP server build failed (see log)." }

# ---- 4. Revit plugin, every band ----
$rp = Join-Path $root 'revit-mcp-plugin\HzBimPlugin\HzBimPlugin.csproj'
foreach ($y in 2020..2027) {
    if ((Run "Revit $y" 'dotnet' @('build',$rp,'-c','Release',"-p:RevitVersion=$y",'--nologo','-v','minimal') $root) -ne 0) { Fail "Revit $y build failed (see log)." }
}

# ---- 5. Navisworks plugin, every year ----
$np = Join-Path $root 'navis-mcp-plugin\HzBimNavisPlugin\HzBimNavisPlugin.csproj'
foreach ($y in 2020..2027) {
    if ((Run "Navisworks $y" 'dotnet' @('build',$np,'-c','Release',"-p:NavisYear=$y",'--nologo','-v','minimal') $root) -ne 0) { Fail "Navisworks $y build failed (see log)." }
}

# ---- 6. Unreal bridge exe (optional - its build script is not in this repo) ----
$ue = Join-Path $root 'unreal-mcp-server'
if (Test-Path (Join-Path $ue 'build\build-exe.js')) {
    Run 'Unreal server: npm ci' 'npm.cmd' @('ci','--no-audit','--no-fund') $ue | Out-Null
    Run 'Unreal server: build exe' 'npm.cmd' @('run','build:exe') $ue | Out-Null
} else { Log ""; Log "Unreal bridge: skipped (optional, not needed for Revit/Navisworks)." }

# ---- 7. Compile the wizard ----
$iss = Join-Path $root 'installer\setup.iss'
if ((Run 'Inno Setup compile' $iscc @($iss) (Join-Path $root 'installer')) -ne 0) { Fail "Installer compile failed (see log)." }
$exe = Join-Path $root 'installer\output\HZ-BIM.exe'
if (-not (Test-Path $exe)) { Fail "Inno Setup ran but $exe was not produced." }
$final = Join-Path $root 'HZ-BIM-Setup.exe'
Copy-Item $exe $final -Force
Log ""; Log "==== DONE ===="
Log "Installer: $final  ($([math]::Round((Get-Item $final).Length/1MB,1)) MB)"
Log "Double-click HZ-BIM-Setup.exe to install (pick your Revit/Navisworks versions in the wizard)."
Read-Host 'Press Enter to close'
