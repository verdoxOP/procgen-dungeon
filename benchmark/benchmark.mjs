// Benchmarks the Rust and C# generators against each other.
//
//   node benchmark/benchmark.mjs [--seeds 1000] [--warmup 3] [--warm-repeats 3] [--out benchmark/results]
//
// Build the generators first (build-generators.ps1 / .sh); this script runs the programs in the game's
// generators/ folder, the same ones the game uses. Two measurements:
//
//   cold  one process per dungeon, like the game runs it. Measures the process time (start-up included)
//         and the generator's own "stats". For C# this includes the JIT compiling every method once.
//   warm  one process generates all seeds (--runs) after --warmup passes over the same seeds,
//         so only the algorithm itself is measured. Repeated --warm-repeats times.
//
// Writes cold.csv, warm.csv and summary.md to --out.

import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const STEPS = ["rooms_ms", "edges_ms", "tree_ms", "doors_ms", "bfs_ms", "population_ms", "total_ms"];
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const exe = os.platform() === "win32" ? ".exe" : "";
const GENERATORS = [
  { name: "rust", file: "procgen_dungeon" + exe },
  { name: "csharp", file: "procgen-csharp" + exe },
];

function parseArgs(argv) {
  const options = {
    seeds: 1000,
    warmup: 3,
    warmRepeats: 3,
    out: path.join(repoRoot, "benchmark", "results"),
    generatorsDir: path.join(repoRoot, "GoDot-Project", "dungeon-crawler", "generators"),
  };
  const names = { "--seeds": "seeds", "--warmup": "warmup", "--warm-repeats": "warmRepeats", "--out": "out", "--generators": "generatorsDir" };
  for (let i = 0; i < argv.length; i += 2) {
    const key = names[argv[i]];
    if (!key || argv[i + 1] === undefined) {
      console.error(`unknown or incomplete argument: ${argv[i]}`);
      process.exit(2);
    }
    options[key] = ["out", "generatorsDir"].includes(key) ? path.resolve(argv[i + 1]) : Number(argv[i + 1]);
  }
  return options;
}

// Runs a generator and returns its stdout. stderr (the logs) is thrown away.
function run(generator, args) {
  return execFileSync(generator.path, args, { stdio: ["ignore", "pipe", "ignore"], maxBuffer: 1 << 28 }).toString();
}

// Cold: one process per seed. Rust and C# take turns per seed, so a slow moment on the machine hits both.
function measureCold(generators, seeds) {
  const rows = [];
  for (let seed = 0; seed < seeds; seed++) {
    for (const generator of generators) {
      const start = process.hrtime.bigint();
      const output = run(generator, ["--seed", String(seed)]);
      const processMs = Number(process.hrtime.bigint() - start) / 1e6;
      const stats = JSON.parse(output).stats;
      rows.push({ generator: generator.name, seed, process_ms: processMs, ...stats });
    }
    if ((seed + 1) % 100 === 0) console.error(`cold: ${seed + 1}/${seeds} seeds`);
  }
  return rows;
}

// Warm: all seeds in one process, after the warmup passes.
function measureWarm(generators, seeds, warmup, repeats) {
  const rows = [];
  for (let repeat = 1; repeat <= repeats; repeat++) {
    for (const generator of generators) {
      const output = run(generator, ["--seed", "0", "--runs", String(seeds), "--warmup", String(warmup)]);
      for (const line of output.trim().split(/\r?\n/)) {
        const result = JSON.parse(line);
        if (result.failed) throw new Error(`${generator.name} failed on seed ${result.seed}`);
        rows.push({ generator: generator.name, repeat, seed: result.seed, ...result.stats });
      }
      console.error(`warm: ${generator.name} repeat ${repeat}/${repeats} done`);
    }
  }
  return rows;
}

function describe(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const at = (q) => sorted[Math.min(sorted.length - 1, Math.floor(q * sorted.length))];
  const mean = values.reduce((a, b) => a + b, 0) / values.length;
  const sd = Math.sqrt(values.reduce((a, b) => a + (b - mean) ** 2, 0) / values.length);
  return { mean, median: at(0.5), p95: at(0.95), min: sorted[0], max: sorted[sorted.length - 1], sd };
}

function toCsv(rows, columns) {
  return [columns.join(","), ...rows.map((r) => columns.map((c) => r[c]).join(","))].join("\n") + "\n";
}

const fmt = (x) => (x >= 100 ? x.toFixed(1) : x >= 1 ? x.toFixed(3) : x.toFixed(4));

// One table per measurement: every metric, both generators, and how many times slower C# is (median).
function table(rows, metrics) {
  const lines = [
    "| Metric | Rust median | Rust mean | Rust p95 | C# median | C# mean | C# p95 | C# / Rust (median) |",
    "|---|---|---|---|---|---|---|---|",
  ];
  for (const metric of metrics) {
    const rust = describe(rows.filter((r) => r.generator === "rust").map((r) => r[metric]));
    const csharp = describe(rows.filter((r) => r.generator === "csharp").map((r) => r[metric]));
    const ratio = rust.median > 0 ? (csharp.median / rust.median).toFixed(1) + "×" : "n/a";
    lines.push(`| \`${metric}\` | ${fmt(rust.median)} | ${fmt(rust.mean)} | ${fmt(rust.p95)} | ${fmt(csharp.median)} | ${fmt(csharp.mean)} | ${fmt(csharp.p95)} | ${ratio} |`);
  }
  return lines.join("\n");
}

// Both generators must have done the same work: same number of room generation attempts per seed.
function checkSameWork(rows) {
  const attempts = new Map();
  let mismatches = 0;
  for (const r of rows) {
    const key = `${r.repeat ?? 0}:${r.seed}`;
    if (!attempts.has(key)) attempts.set(key, r.generation_attempts);
    else if (attempts.get(key) !== r.generation_attempts) mismatches++;
  }
  return mismatches;
}

const options = parseArgs(process.argv.slice(2));
const generators = GENERATORS.map((g) => ({ ...g, path: path.join(options.generatorsDir, g.file) }));
for (const g of generators) {
  if (!existsSync(g.path)) {
    console.error(`missing ${g.path}: build the generators first (build-generators.ps1 / .sh)`);
    process.exit(1);
  }
}

console.error(`benchmarking ${options.seeds} seeds, cold and warm (warmup ${options.warmup}, ${options.warmRepeats} repeats)`);
const started = new Date();
const cold = measureCold(generators, options.seeds);
const warm = measureWarm(generators, options.seeds, options.warmup, options.warmRepeats);

mkdirSync(options.out, { recursive: true });
writeFileSync(path.join(options.out, "cold.csv"), toCsv(cold, ["generator", "seed", "process_ms", ...STEPS, "generation_attempts"]));
writeFileSync(path.join(options.out, "warm.csv"), toCsv(warm, ["generator", "repeat", "seed", ...STEPS, "generation_attempts"]));

const cpu = os.cpus()[0]?.model.trim() ?? "unknown";
const summary = `# Benchmark results

- **Date:** ${started.toISOString().slice(0, 16).replace("T", " ")} UTC
- **Machine:** ${cpu}, ${os.cpus().length} logical cores, ${(os.totalmem() / 2 ** 30).toFixed(0)} GB RAM
- **OS:** ${os.type()} ${os.release()} (${os.arch()}), Node ${process.version}
- **Seeds:** 0–${options.seeds - 1}
- **Same work check:** ${checkSameWork(cold) + checkSameWork(warm)} seeds where the generation attempts differ between Rust and C# (should be 0)

All times in milliseconds. \`total_ms\` is the sum of the six steps, measured inside the generator.

## Cold: one process per dungeon (like the game)

One run per seed, ${options.seeds} dungeons per generator. \`process_ms\` is the whole process measured from outside (start-up, generation, JSON, exit).

${table(cold, ["process_ms", ...STEPS])}

## Warm: all seeds in one process

\`--runs ${options.seeds} --warmup ${options.warmup}\`, repeated ${options.warmRepeats} times: ${options.seeds * options.warmRepeats} dungeons per generator. Only the generation steps, after the warmup passes.

${table(warm, STEPS)}

Raw data: \`cold.csv\`, \`warm.csv\`.
`;
writeFileSync(path.join(options.out, "summary.md"), summary);
console.log(summary);
