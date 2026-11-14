# HZ-BIM: find every Claude Desktop config on this PC and make sure each lists the HZ-BIM servers.
# Claude Desktop must be fully closed (File -> Exit) or it may overwrite the file.
# Each changed file is backed up first (<file>.hzbim-backup). Report: claude-config-log.txt

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$log  = Join-Path $root 'claude-config-log.txt'
Set-Content -Path $log -Value "Claude config fix  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Encoding UTF8
function Log($m) { Write-Host $m; Add-Content -Path $log -Value $m -Encoding UTF8 }

if (Get-Process -Name 'Claude' -ErrorAction SilentlyContinue) {
    Log "Claude is still running. Close it fully (File -> Exit, also from the tray icon), then run this again."
    Read-Host 'Press Enter to close'; exit 1
}

# Server location: installed copy first, then this repo.
$server = @("$env:ProgramFiles\HzBim\server\build\index.js", (Join-Path $root 'revit-mcp-server\build\index.js')) |
    Where-Object { Test-Path $_ } | Select-Object -First 1
$node = @("$env:ProgramFiles\HzBim\nodejs\node.exe", "$env:ProgramFiles\nodejs\node.exe") |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $node) { $node = (Get-Command node -ErrorAction SilentlyContinue).Source }
Log "Server: $server"; Log "Node:   $node"
if (-not $server -or -not $node) { Log "Server or Node not found - install HZ-BIM first."; Read-Host 'Press Enter to close'; exit 1 }

# Search every place Claude Desktop (normal or Microsoft Store build) can keep its config.
$roots = @($env:APPDATA, $env:LOCALAPPDATA) | Where-Object { $_ -and (Test-Path $_) }
$found = @()
foreach ($r in $roots) {
    $found += Get-ChildItem -Path $r -Filter 'claude_desktop_config.json' -Recurse -File -ErrorAction SilentlyContinue -Depth 8 |
        Select-Object -ExpandProperty FullName
}
$found = $found | Select-Object -Unique
if ($found.Count -eq 0) { Log "No claude_desktop_config.json found anywhere." }

$utf8 = New-Object System.Text.UTF8Encoding $false
foreach ($f in $found) {
    Log ""; Log "FILE: $f  (modified $((Get-Item $f).LastWriteTime))"
    try {
        $raw = [IO.File]::ReadAllText($f); if ($raw.Length -gt 0 -and $raw[0] -eq [char]0xFEFF) { $raw = $raw.Substring(1) }
        $j = if ($raw.Trim()) { $raw | ConvertFrom-Json } else { [pscustomobject]@{} }
    } catch { Log "   not valid JSON - left untouched ($($_.Exception.Message))"; continue }
    if (-not $j.PSObject.Properties['mcpServers']) { $j | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{}) }
    foreach ($p in $j.mcpServers.PSObject.Properties) { Log ("   before: {0} -> {1}" -f $p.Name, (@($p.Value.args) -join ' ')) }

    $full  = [pscustomobject]@{ command = $node; args = @($server); env = [pscustomobject]@{} }
    $navis = [pscustomobject]@{ command = $node; args = @($server); env = [pscustomobject]@{ HZBIM_SCOPE = 'navis' } }
    $j.mcpServers | Add-Member -NotePropertyName 'HZ-BIM' -NotePropertyValue $full -Force
    $j.mcpServers | Add-Member -NotePropertyName 'HZ-BIM-Navis' -NotePropertyValue $navis -Force

    Copy-Item $f "$f.hzbim-backup" -Force
    [IO.File]::WriteAllText($f, ($j | ConvertTo-Json -Depth 20), $utf8)
    Log "   OK: HZ-BIM + HZ-BIM-Navis set (backup: $f.hzbim-backup)"
}

Log ""; Log "Done. Open Claude Desktop again, then Settings -> Desktop app -> Local MCP servers should list HZ-BIM."
Log "Tell Claude: 'config done'."
Read-Host 'Press Enter to close'
