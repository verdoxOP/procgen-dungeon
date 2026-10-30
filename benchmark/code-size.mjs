// Counts the lines of code per pipeline step in the Rust and C# generators (static program analysis).
//
//   node benchmark/code-size.mjs [--out benchmark/results]
//
// Writes code-size.md. Counting rules:
//   code       lines that are not empty and not only a comment
//   logic      code lines that are not only brackets ("{", "}", "};", ")" ...). C# puts an opening
//              brace on its own line and Rust doesn't, so this is the fairer number to compare.
//   comments   lines that are only a comment
// Rust tests live in a #[cfg(test)] module at the bottom of each file; those lines are counted as tests.

import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const rustSrc = path.join(repoRoot, "Algorithms", "rust", "procgen_dungeon", "src");
const csharpSrc = path.join(repoRoot, "Algorithms", "csharp", "procgen-csharp", "procgen-csharp");
const csharpTests = path.join(repoRoot, "Algorithms", "csharp", "procgen-csharp", "procgen-csharp.Tests");

// Which files implement which step. Rust gets the RNG from the rand / rand_pcg crates.
const STEPS = [
  { step: "RNG (Pcg32)", rust: [], csharp: ["Pcg32.cs"] },
  { step: "Rooms", rust: ["room.rs", "room_generation.rs"], csharp: ["Room.cs", "RoomGeneration.cs"] },
  { step: "Room validation", rust: ["validation.rs"], csharp: ["Validation.cs"] },
  { step: "Edges", rust: ["edge.rs"], csharp: ["Edge.cs", "EdgeGeneration.cs"] },
  { step: "Spanning tree (Prim)", rust: ["tree.rs"], csharp: ["SpanningTree.cs"] },
  { step: "Doors", rust: ["door.rs"], csharp: ["Door.cs", "DoorGeneration.cs"] },
  { step: "BFS end room", rust: ["bfs.rs"], csharp: ["Bfs.cs"] },
  { step: "Population + validation", rust: ["population.rs"], csharp: ["Spawnable.cs", "Population.cs"] },
  { step: "JSON + stats", rust: ["dungeon_json.rs"], csharp: ["DungeonJson.cs", "GenerationStats.cs"] },
  { step: "Constants", rust: ["constants.rs"], csharp: ["Constants.cs"] },
  { step: "Main (arguments, pipeline, benchmark mode)", rust: ["main.rs"], csharp: ["Program.cs", "GeneratedDungeon.cs"] },
];
// Only in Rust, for debugging; not part of the generator's output.
const RUST_DEBUG = ["grid.rs", "tree_visualization.rs"];
const CSHARP_TEST_FILES = ["RoomTests.cs", "RoomGenerationTests.cs", "ValidationTests.cs", "EdgeGenerationTests.cs",
  "SpanningTreeTests.cs", "DoorGenerationTests.cs", "BfsTests.cs", "PopulationTests.cs", "TestDungeon.cs"];

const BRACKETS_ONLY = /^[{}()\[\];,]+$/;

function countLines(lines) {
  const result = { code: 0, logic: 0, comments: 0 };
  let inBlockComment = false;
  for (const raw of lines) {
    const line = raw.trim();
    if (inBlockComment) {
      result.comments++;
      if (line.includes("*/")) inBlockComment = false;
      continue;
    }
    if (line === "") continue;
    if (line.startsWith("//")) { result.comments++; continue; }
    if (line.startsWith("/*")) { result.comments++; inBlockComment = !line.includes("*/"); continue; }
    result.code++;
    if (!BRACKETS_ONLY.test(line)) result.logic++;
  }
  return result;
}

// Splits a Rust file into production code and its test module.
function rustFile(name) {
  const lines = readFileSync(path.join(rustSrc, name), "utf8").split(/\r?\n/);
  const testStart = lines.findIndex((l) => l.trim() === "#[cfg(test)]");
  return testStart < 0
    ? { code: countLines(lines), tests: countLines([]) }
    : { code: countLines(lines.slice(0, testStart)), tests: countLines(lines.slice(testStart)) };
}

function csharpFile(dir, name) {
  return countLines(readFileSync(path.join(dir, name), "utf8").split(/\r?\n/));
}

const add = (a, b) => ({ code: a.code + b.code, logic: a.logic + b.logic, comments: a.comments + b.comments });
const zero = () => ({ code: 0, logic: 0, comments: 0 });
const ratio = (cs, rs) => (rs > 0 ? (cs / rs).toFixed(2) + "×" : "–");

const outDir = process.argv[2] === "--out" ? path.resolve(process.argv[3]) : path.join(repoRoot, "benchmark", "results");

let rustTotal = zero(), csharpTotal = zero(), rustTests = zero(), rustTestCount = 0;
const rows = [];
for (const { step, rust, csharp } of STEPS) {
  let r = zero(), c = zero();
  for (const f of rust) {
    const counted = rustFile(f);
    r = add(r, counted.code);
    rustTests = add(rustTests, counted.tests);
    rustTestCount += (readFileSync(path.join(rustSrc, f), "utf8").match(/#\[test\]/g) ?? []).length;
  }
  for (const f of csharp) c = add(c, csharpFile(csharpSrc, f));
  rustTotal = add(rustTotal, r);
  csharpTotal = add(csharpTotal, c);
  rows.push(`| ${step} | ${rust.map((f) => `\`${f}\``).join(", ") || "*(crates `rand`, `rand_pcg`)*"} | ${r.code} | ${r.logic} | ${csharp.map((f) => `\`${f}\``).join(", ")} | ${c.code} | ${c.logic} | ${ratio(c.logic, r.logic)} |`);
}

let rustDebug = zero();
for (const f of RUST_DEBUG) rustDebug = add(rustDebug, rustFile(f).code);
let csharpTestLines = zero(), csharpTestCount = 0;
for (const f of CSHARP_TEST_FILES) {
  csharpTestLines = add(csharpTestLines, csharpFile(csharpTests, f));
  csharpTestCount += (readFileSync(path.join(csharpTests, f), "utf8").match(/\[Fact\]/g) ?? []).length;
}

const pcg = csharpFile(csharpSrc, "Pcg32.cs");
const generators = path.join(repoRoot, "GoDot-Project", "dungeon-crawler", "generators");
const exe = os.platform() === "win32" ? ".exe" : "";
const size = (f) => (existsSync(path.join(generators, f)) ? `${(statSync(path.join(generators, f)).size / 1024).toFixed(0)} KB` : "not built");

const report = `# Code size: Rust vs C#

Static program analysis of both generators, counted by \`benchmark/code-size.mjs\` on ${new Date().toISOString().slice(0, 10)}.

- **code:** lines that are not empty and not only a comment
- **logic:** code lines that are not only brackets. C# puts \`{\` on its own line, Rust doesn't, so compare this column.

## Per step

| Step | Rust files | Rust code | Rust logic | C# files | C# code | C# logic | C# / Rust (logic) |
|---|---|---|---|---|---|---|---|
${rows.join("\n")}
| **Total** | | **${rustTotal.code}** | **${rustTotal.logic}** | | **${csharpTotal.code}** | **${csharpTotal.logic}** | **${ratio(csharpTotal.logic, rustTotal.logic)}** |
| Total without the RNG | | ${rustTotal.code} | ${rustTotal.logic} | | ${csharpTotal.code - pcg.code} | ${csharpTotal.logic - pcg.logic} | ${ratio(csharpTotal.logic - pcg.logic, rustTotal.logic)} |

Comment lines: Rust ${rustTotal.comments}, C# ${csharpTotal.comments}.

Not counted above: Rust's debug output (\`${RUST_DEBUG.join("`, `")}\`, ${rustDebug.code} code lines), which C# doesn't have.

## Tests

| | Tests | Code lines | Where |
|---|---|---|---|
| Rust | ${rustTestCount} | ${rustTests.code} | \`#[cfg(test)] mod tests\` at the bottom of each file |
| C# | ${csharpTestCount} | ${csharpTestLines.code} | separate xUnit project \`procgen-csharp.Tests\` |

## Dependencies and build

| | Rust | C# |
|---|---|---|
| Libraries | \`rand\`, \`rand_pcg\`, \`serde\`, \`serde_json\` (crates.io) | none, only .NET's own library (\`System.Text.Json\`, \`System.Diagnostics\`) |
| RNG | from the \`rand_pcg\` crate | written by hand (\`Pcg32.cs\`, ${pcg.logic} logic lines) to give the same numbers as Rust |
| JSON | \`#[derive(Serialize)]\` on the structs | separate DTO classes with \`[JsonPropertyName]\` |
| Program in \`generators/\` | ${size("procgen_dungeon" + exe)}, native, runs on its own | ${size("procgen-csharp" + exe)}, needs the .NET 8 runtime installed |
`;

mkdirSync(outDir, { recursive: true });
writeFileSync(path.join(outDir, "code-size.md"), report);
console.log(report);
