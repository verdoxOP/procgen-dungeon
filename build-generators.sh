#!/usr/bin/env bash
# Builds both dungeon generators and copies them into the game's generators/ folder,
# so the Godot menu lists them. Linux / macOS. For Windows: build-generators.ps1
#
# Usage, from the repository root:
#   ./build-generators.sh
#
# Needs: .NET SDK 8+ (C# generator) and/or Rust with cargo (Rust generator).
# A generator whose tools are missing is skipped with a warning.

set -u

root="$(cd "$(dirname "$0")" && pwd)"
generators="$root/GoDot-Project/dungeon-crawler/generators"
csharp_project="$root/Algorithms/csharp/procgen-csharp/procgen-csharp"
rust_project="$root/Algorithms/rust/procgen_dungeon"

built=()
failed=()

# Runs a generator once to check it follows the contract: exit code 0 and JSON on stdout.
test_generator() {
    local output
    output="$("$1" --seed 1 2>/dev/null)" || return 1
    [[ "$output" == "{"* ]]
}

mkdir -p "$generators"

# The game looks for files without an extension on Linux and macOS.
case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)  rid="linux-x64" ;;
    Linux-aarch64) rid="linux-arm64" ;;
    Darwin-arm64)  rid="osx-arm64" ;;
    Darwin-*)      rid="osx-x64" ;;
    *)             rid="" ;;
esac

# --- C# generator ----------------------------------------------------------------------
echo; echo "== C# generator =="
if ! command -v dotnet >/dev/null 2>&1; then
    echo "WARNING: dotnet not found, skipping the C# generator. Install the .NET SDK 8 or newer." >&2
    failed+=("C# (dotnet missing)")
elif [[ -z "$rid" ]]; then
    echo "WARNING: unknown platform $(uname -s)-$(uname -m), skipping the C# generator." >&2
    failed+=("C# (unknown platform)")
else
    publish_dir="$csharp_project/bin/publish-generator"
    # Single small executable that uses the installed .NET runtime.
    if dotnet publish "$csharp_project" -c Release -r "$rid" -p:SelfContained=false -p:PublishSingleFile=true -o "$publish_dir" --nologo; then
        cp "$publish_dir/procgen-csharp" "$generators/procgen-csharp"
        chmod +x "$generators/procgen-csharp"
        if test_generator "$generators/procgen-csharp"; then built+=("procgen-csharp"); else failed+=("C# (built, but --seed 1 didn't give JSON)"); fi
    else
        failed+=("C# (build failed)")
    fi
fi

# --- Rust generator --------------------------------------------------------------------
echo; echo "== Rust generator =="
if ! command -v cargo >/dev/null 2>&1; then
    echo "WARNING: cargo not found, skipping the Rust generator. Install Rust from https://rustup.rs" >&2
    failed+=("Rust (cargo missing)")
elif cargo build --release --manifest-path "$rust_project/Cargo.toml"; then
    cp "$rust_project/target/release/procgen_dungeon" "$generators/procgen_dungeon"
    chmod +x "$generators/procgen_dungeon"
    if test_generator "$generators/procgen_dungeon"; then built+=("procgen_dungeon"); else failed+=("Rust (built, but --seed 1 didn't give JSON)"); fi
else
    failed+=("Rust (build failed)")
fi

# --- Summary ---------------------------------------------------------------------------
echo; echo "== Done =="
echo "Generators folder: $generators"
for name in "${built[@]+"${built[@]}"}"; do echo "  OK      $name"; done
for name in "${failed[@]+"${failed[@]}"}"; do echo "  MISSING $name"; done
if [[ ${#built[@]} -gt 0 ]]; then echo; echo "Start the game and pick a generator in the menu."; fi
[[ ${#failed[@]} -eq 0 ]]
