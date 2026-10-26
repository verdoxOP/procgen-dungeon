# Builds both dungeon generators and copies them into the game's generators/ folder,
# so the Godot menu lists them. Windows / PowerShell. For Linux and macOS: build-generators.sh
#
# Usage, from the repository root:
#   powershell -ExecutionPolicy Bypass -File .\build-generators.ps1
#
# Needs: .NET SDK 8+ (C# generator) and/or Rust with cargo (Rust generator).
# A generator whose tools are missing is skipped with a warning.

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$generators = Join-Path $root "GoDot-Project\dungeon-crawler\generators"
$csharpProject = Join-Path $root "Algorithms\csharp\procgen-csharp\procgen-csharp"
$rustProject = Join-Path $root "Algorithms\rust\procgen_dungeon"

$built = @()
$failed = @()

function Test-Tool($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

# Runs a generator once to check it follows the contract: exit code 0 and JSON on stdout.
function Test-Generator($exe) {
    # Windows PowerShell turns redirected stderr into errors, which "Stop" would make fatal.
    $ErrorActionPreference = "Continue"
    $output = & $exe --seed 1 2>$null
    return ($LASTEXITCODE -eq 0) -and (($output -join "").TrimStart().StartsWith("{"))
}

New-Item -ItemType Directory -Force $generators | Out-Null

# --- C# generator ----------------------------------------------------------------------
Write-Host "`n== C# generator ==" -ForegroundColor Cyan
if (-not (Test-Tool "dotnet")) {
    Write-Warning "dotnet not found, skipping the C# generator. Install the .NET SDK 8 or newer."
    $failed += "C# (dotnet missing)"
} else {
    $publishDir = Join-Path $csharpProject "bin\publish-generator"
    # Single small exe that uses the installed .NET runtime (about 170 KB instead of 67 MB).
    & dotnet publish $csharpProject -c Release -r win-x64 -p:SelfContained=false -p:PublishSingleFile=true -o $publishDir --nologo
    if ($LASTEXITCODE -ne 0) {
        $failed += "C# (build failed)"
    } else {
        $target = Join-Path $generators "procgen-csharp.exe"
        Copy-Item (Join-Path $publishDir "procgen-csharp.exe") $target -Force
        if (Test-Generator $target) { $built += "procgen-csharp" } else { $failed += "C# (built, but --seed 1 didn't give JSON)" }
    }
}

# --- Rust generator --------------------------------------------------------------------
Write-Host "`n== Rust generator ==" -ForegroundColor Cyan
if (-not (Test-Tool "cargo")) {
    Write-Warning "cargo not found, skipping the Rust generator. Install Rust from https://rustup.rs"
    $failed += "Rust (cargo missing)"
} else {
    # The GNU toolchain without a full MinGW install can't build getrandom's default Windows
    # backend. The legacy backend avoids that and doesn't change the generator's output
    # (all its randomness comes from the seed). The MSVC toolchain doesn't need this.
    $previousFlags = $env:RUSTFLAGS
    $hostLine = (& rustc -vV | Select-String "^host:").ToString()
    if ($hostLine -match "windows-gnu") {
        $env:RUSTFLAGS = '--cfg getrandom_backend="windows_legacy"'
    }
    try {
        & cargo build --release --manifest-path (Join-Path $rustProject "Cargo.toml")
        $cargoExit = $LASTEXITCODE
    } finally {
        $env:RUSTFLAGS = $previousFlags
    }
    if ($cargoExit -ne 0) {
        $failed += "Rust (build failed)"
    } else {
        $target = Join-Path $generators "procgen_dungeon.exe"
        Copy-Item (Join-Path $rustProject "target\release\procgen_dungeon.exe") $target -Force
        if (Test-Generator $target) { $built += "procgen_dungeon" } else { $failed += "Rust (built, but --seed 1 didn't give JSON)" }
    }
}

# --- Summary ---------------------------------------------------------------------------
Write-Host "`n== Done ==" -ForegroundColor Cyan
Write-Host "Generators folder: $generators"
foreach ($name in $built) { Write-Host "  OK      $name" -ForegroundColor Green }
foreach ($name in $failed) { Write-Host "  MISSING $name" -ForegroundColor Yellow }
if ($built.Count -gt 0) {
    Write-Host "`nStart the game and pick a generator in the menu."
}
if ($failed.Count -gt 0) { exit 1 }
