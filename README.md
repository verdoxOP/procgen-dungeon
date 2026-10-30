# procgen-dungeon
Procedural dungeon generation and validation system written in Rust, providing generated dungeon data to a Godot game.

A second generator in C# produces exactly the same dungeons, so the two languages can be compared. Both are played in the same Godot game.

| Part | Folder | Docs |
|---|---|---|
| Rust generator | `Algorithms/rust/procgen_dungeon/` | [README](Algorithms/rust/procgen_dungeon/README.md) |
| C# generator | `Algorithms/csharp/procgen-csharp/` | [README](Algorithms/csharp/procgen-csharp/README.md) |
| Godot game | `GoDot-Project/dungeon-crawler/` | [JSON format](GoDot-Project/dungeon-crawler/test_data/FORMAT.md) |

## Getting started after cloning

You need:

| Tool | For |
|---|---|
| [Godot 4.7](https://godotengine.org/) (standard edition) | the game |
| [.NET SDK 8 or newer](https://dotnet.microsoft.com/download) | the C# generator |
| [Rust](https://rustup.rs) with cargo | the Rust generator |

1. **Build the generators.** From the repository root:

   Windows (PowerShell):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build-generators.ps1
   ```
   Linux / macOS:
   ```sh
   ./build-generators.sh
   ```

   This builds both generators and copies them into `GoDot-Project/dungeon-crawler/generators/`. Each one is tested once with `--seed 1`. If a tool is missing, that generator is skipped with a warning. The built programs are not in git, so run the script again after pulling code changes.

2. **Open the game.** Open `GoDot-Project/dungeon-crawler/project.godot` in Godot and press F5.

3. **Pick a generator** in the menu (`procgen-csharp`, `procgen_dungeon`, or the built-in test file), optionally a seed, and press Start.

## Previewing a dungeon in the editor

Open `Scenes/dungeon_preview.tscn` in Godot. The whole dungeon for one seed is drawn in the 2D view, without running the game. In the Inspector:

| Setting | |
|---|---|
| Generator | dropdown with every program in `generators/`, plus the test file |
| Seed Value | changing it regenerates right away |
| Generate / Random seed | run again, or pick a new seed |
| Show | toggle the door lines, spawnables and room labels |

Start room is outlined green, the end room red. Yellow lines connect the two sides of each door. Passive enemies are drawn slightly faded. The text above the map shows the counts and how long the generator took.

## Benchmark

After building the generators:

```sh
node benchmark/benchmark.mjs
```

Needs [Node.js](https://nodejs.org) 18 or newer. Compares Rust and C# over seeds 0–999, cold (one process per dungeon, like the game) and warm (one process, after warmup). See [benchmark/README.md](benchmark/README.md).

## How the game talks to a generator

The game runs `generators/<name> --seed <number>` and reads the dungeon JSON from stdout. Any program that follows this contract shows up in the menu under its file name:

| Rule | |
|---|---|
| arguments | `--seed <int>` (the generators also accept `--runs <n> [--warmup <n>]` for the benchmark) |
| stdout | only the dungeon JSON (format version 2) |
| stderr | logs |
| exit code | 0 = ok, 1 = generation failed, 2 = invalid arguments |
