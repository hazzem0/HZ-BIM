# Deploy HZ-BIM Plugin to all installed Revit versions (2020-2027).
# Each Revit version gets its own build, compiled against that year's API:
#   bin\R<year>\Release\<tfm>  ->  C:\Program Files\HzBim\plugin\R<year>
# Build them first with:  installer\build-installer.ps1  (or per band:
#   dotnet build -c Release -p:RevitVersion=<year>)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$binRoot = Join-Path $scriptDir "revit-mcp-plugin\HzBimPlugin\bin"
$destBase = "C:\Program Files\HzBim\plugin"

# Target framework per Revit version — must match HzBimPlugin.csproj
$bandTfm = @{
  2020 = 'net47'; 2021 = 'net48'; 2022 = 'net48'; 2023 = 'net48'
  2024 = 'net48'; 2025 = 'net8.0-windows'; 2026 = 'net8.0-windows'; 2027 = 'net10.0-windows'
}

# Auto-detect installed Revit versions and deploy that version's own build
$revitVersions = Get-ChildItem "C:\Program Files\Autodesk" -Directory |
Where-Object { $_.Name -match "^Revit (\d{4})$" } |
ForEach-Object { [int]$Matches[1] }

foreach ($year in $revitVersions) {
  if (-not $bandTfm.ContainsKey($year)) {
    Write-Host "  Skipped Revit $year (no build band defined)" -ForegroundColor DarkGray
    continue
  }

  $fw = "R$year"
  $source = Join-Path $binRoot "R$year\Release\$($bandTfm[$year])"
  $destDir = "$destBase\R$year"
  $dllPath = "$destDir\HzBimPlugin.dll"

  if (-not (Test-Path $source)) {
    Write-Host "  Skipped Revit $year — not built. Run: dotnet build -c Release -p:RevitVersion=$year" -ForegroundColor Yellow
    continue
  }

  if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
  Copy-Item "$source\*" "$destDir\" -Force -Recurse

  $addinDir = "C:\ProgramData\Autodesk\Revit\Addins\$year"
  if (-not (Test-Path $addinDir)) { New-Item -ItemType Directory -Path $addinDir -Force | Out-Null }

  # Legacy cleanup: remove old RevitMCP files
  $legacyAddin = Join-Path $addinDir "RevitMCP.addin"
  $legacyDir = Join-Path $addinDir "RevitMCP"
  if (Test-Path $legacyAddin) { Remove-Item $legacyAddin -Force; Write-Host "  Removed legacy RevitMCP.addin for Revit $year" -ForegroundColor DarkYellow }
  if (Test-Path $legacyDir) { Remove-Item $legacyDir -Recurse -Force; Write-Host "  Removed legacy RevitMCP/ folder for Revit $year" -ForegroundColor DarkYellow }

  $addinContent = @"
<?xml version="1.0" encoding="utf-8"?>
<RevitAddIns>
  <AddIn Type="Application">
    <Name>HZ-BIM Plugin</Name>
    <Assembly>$dllPath</Assembly>
    <FullClassName>HzBimPlugin.Core.Application</FullClassName>
    <ClientId>32B3AD35-5306-4D99-9653-CD90FACAD3B4</ClientId>
    <VendorId>HazemAhmed</VendorId>
    <VendorDescription>AI-Powered HZ-BIM Plugin by Hazem Ahmed Ali</VendorDescription>
  </AddIn>
</RevitAddIns>
"@
  $addinContent | Out-File -Encoding utf8 "$addinDir\HzBim.addin" -Force
  Write-Host "Deployed addin for Revit $year ($fw)"
}

# Verify — compare each deployed DLL against the build it came from, so a
# silently-failed copy (e.g. no elevation) cannot look like success.
Write-Host ""
$mismatch = $false
foreach ($year in ($revitVersions | Sort-Object)) {
  if (-not $bandTfm.ContainsKey($year)) { continue }
  $src = Get-Item (Join-Path $binRoot "R$year\Release\$($bandTfm[$year])\HzBimPlugin.dll") -ErrorAction SilentlyContinue
  $dst = Get-Item "$destBase\R$year\HzBimPlugin.dll" -ErrorAction SilentlyContinue
  if (-not $src) { continue }
  if (-not $dst) {
    Write-Host "R$year  NOT DEPLOYED — target missing (elevation needed?)" -ForegroundColor Red
    $mismatch = $true
  }
  elseif ($src.Length -ne $dst.Length -or $src.LastWriteTime -ne $dst.LastWriteTime) {
    Write-Host "R$year  STALE — deployed copy differs from the build" -ForegroundColor Red
    Write-Host "        built:    $($src.Length) bytes  $($src.LastWriteTime)"
    Write-Host "        deployed: $($dst.Length) bytes  $($dst.LastWriteTime)"
    $mismatch = $true
  }
  else {
    Write-Host "R$year  OK  $($dst.Length) bytes  $($dst.LastWriteTime)" -ForegroundColor Green
  }
}

Write-Host ""
if ($mismatch) {
  Write-Host "Deploy FAILED — see above. Re-run elevated." -ForegroundColor Red
  exit 1
}
Write-Host "Deployed to Revit versions: $($revitVersions -join ', ')"
Write-Host "Deploy complete!" -ForegroundColor Green
