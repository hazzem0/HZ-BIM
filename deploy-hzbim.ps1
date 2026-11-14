# HZ-BIM one-click deploy (for testing builds made by BUILD-HZ-BIM.bat)
#   Revit      -> %APPDATA%\Autodesk\Revit\Addins\<year>  (no admin)       via Install-NonAdmin.ps1
#   Claude     -> claude_desktop_config.json gets the "HZ-BIM" MCP server  via Install-NonAdmin.ps1
#   Navisworks -> C:\Program Files\Autodesk\Navisworks Manage <year>\Plugins\HzBimNavisPlugin\
#                 (Program Files = admin: ONE UAC prompt for all years)
# Everything is written to deploy-log.txt next to this script.

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$log  = Join-Path $root 'deploy-log.txt'
Set-Content -Path $log -Value "HZ-BIM deploy log  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Encoding UTF8
function Log($msg) { Write-Host $msg; Add-Content -Path $log -Value $msg -Encoding UTF8 }
$summary = @()

# ---- Revit / Navisworks must be closed (their DLLs are locked while running) ----
$running = @(Get-Process -Name 'Revit','Roamer' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName -Unique)
if ($running.Count -gt 0) {
    Log "Close these first, then run again: $($running -join ', ')  (Revit.exe = Revit, Roamer.exe = Navisworks)"
    Read-Host 'Press Enter to close'; exit 1
}

# ---- Record where the MCP server lives (the Revit plugin's "Connect Claude" reads this) ----
$serverJs = Join-Path $root 'revit-mcp-server\build\index.js'
$ptrDir = Join-Path $env:LOCALAPPDATA 'HzBim'
New-Item -ItemType Directory -Force -Path $ptrDir | Out-Null
Set-Content -Path (Join-Path $ptrDir 'server-path.txt') -Value $serverJs -Encoding UTF8
Log "Server path recorded: $serverJs"

# ---- Revit plugin + Claude Desktop config (no admin) ----
Log ""; Log "==== Revit plugin + Claude Desktop (Install-NonAdmin.ps1) ===="
$nonAdmin = Join-Path $root 'Install-NonAdmin.ps1'
$out = & powershell -NoProfile -ExecutionPolicy Bypass -File $nonAdmin 2>&1 | Out-String
Add-Content -Path $log -Value $out -Encoding UTF8
Write-Host $out
$okRevit = ([regex]::Matches($out, '\[OK\] Deployed HzBim.addin for Revit (\d{4})') | ForEach-Object { $_.Groups[1].Value })
if ($okRevit.Count -gt 0) { $summary += "Revit: OK ($($okRevit -join ', '))" } else { $summary += "Revit: FAILED (see log)" }
if ($out -match 'client config\(s\) in place|Merged HZ-BIM') { $summary += "Claude Desktop config: OK" } else { $summary += "Claude Desktop config: check log" }

# ---- Navisworks plugin (admin, one UAC prompt) ----
Log ""; Log "==== Navisworks plugin ===="
$jobs = @()
foreach ($y in 2020..2027) {
    $inst = "C:\Program Files\Autodesk\Navisworks Manage $y"
    if (-not (Test-Path "$inst\Roamer.exe")) { continue }
    $dll = Join-Path $root "navis-mcp-plugin\HzBimNavisPlugin\bin\N$y\Release\net48\HzBimNavisPlugin.dll"
    if (-not (Test-Path $dll)) { Log "Navisworks $y : no build found ($dll) - run BUILD-HZ-BIM.bat first"; $summary += "Navisworks $y : NOT BUILT"; continue }
    $jobs += [pscustomobject]@{ Year = $y; Src = $dll; Dir = "$inst\Plugins\HzBimNavisPlugin" }
}
if ($jobs.Count -eq 0) {
    Log "No Navisworks Manage install with a matching build."
} else {
    $cmd = ''
    foreach ($j in $jobs) {
        $cmd += "New-Item -ItemType Directory -Force -Path '$($j.Dir)' | Out-Null; Copy-Item -LiteralPath '$($j.Src)' -Destination '$($j.Dir)\HzBimNavisPlugin.dll' -Force; "
    }
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
    Log "Asking for admin permission once to copy into Program Files..."
    try {
        Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-EncodedCommand',$enc)
    } catch { Log "Admin permission was declined or failed: $($_.Exception.Message)" }
    foreach ($j in $jobs) {
        $target = "$($j.Dir)\HzBimNavisPlugin.dll"
        if ((Test-Path $target) -and ((Get-Item $target).LastWriteTime -ge (Get-Item $j.Src).LastWriteTime.AddSeconds(-2))) {
            Log "Navisworks $($j.Year): OK -> $target"; $summary += "Navisworks $($j.Year) : OK"
        } else {
            Log "Navisworks $($j.Year): FAILED -> $target"; $summary += "Navisworks $($j.Year) : FAILED"
        }
    }
}

# ---- Claude Desktop diagnostics: which config files exist and which servers they list ----
# Only server names, commands and args are logged - never env values (they can hold API keys).
Log ""; Log "==== Claude Desktop config files ===="
$cands = @("$env:APPDATA\Claude\claude_desktop_config.json")
foreach ($base in @("$env:LOCALAPPDATA\Packages")) {
    if (Test-Path $base) {
        Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(Claude|Anthropic)' } | ForEach-Object {
            Log "Store package: $($_.Name)"
            $cands += Join-Path $_.FullName 'LocalCache\Roaming\Claude\claude_desktop_config.json'
        }
    }
}
Get-ChildItem $env:LOCALAPPDATA -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'claude|anthropic' } | ForEach-Object { Log "LocalAppData folder: $($_.Name)" }
foreach ($c in ($cands | Select-Object -Unique)) {
    if (-not (Test-Path $c)) { Log "MISSING: $c"; continue }
    Log "FOUND:   $c  (modified $((Get-Item $c).LastWriteTime))"
    try {
        $j = Get-Content $c -Raw | ConvertFrom-Json
        if ($j.mcpServers) {
            foreach ($prop in $j.mcpServers.PSObject.Properties) {
                Log ("   - {0}: {1} {2}" -f $prop.Name, $prop.Value.command, (@($prop.Value.args) -join ' '))
            }
        } else { Log "   (no mcpServers section)" }
    } catch { Log "   NOT VALID JSON: $($_.Exception.Message)" }
}

Log ""; Log "==== SUMMARY ===="; $summary | ForEach-Object { Log $_ }
Log ""
Log "Next: restart Claude Desktop, open Revit -> HZ-BIM tab -> Start HZ-BIM."
Log "      open Navisworks Manage -> HZ-BIM tab -> Start HZ-BIM."
Log "Done. Tell Claude: 'deploy done'."
Read-Host 'Press Enter to close'
