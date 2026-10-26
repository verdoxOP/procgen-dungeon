# Random number generator

[← Documentation home](README.md)

Covers [`Pcg32.cs`](../procgen-csharp/Pcg32.cs).

## Why not `System.Random`?

The Rust generator uses `Pcg32` from the `rand_pcg` crate. C#'s built-in `System.Random` is a different algorithm, so the same seed would give completely different numbers, and therefore a different dungeon. That would make the language comparison unfair: the two generators would do different amounts of work (more or fewer placement attempts, retries, …), so differences in speed could come from luck instead of from the language.

So the C# version contains its own port of `Pcg32`, written to give **bit-for-bit the same numbers** as Rust. That has two benefits:

- **fair comparison**: same seed → same dungeon → same work in both languages,
- **free testing**: the C# output can be compared directly with the Rust output (see [Verification](verification.md)).

Getting the same numbers takes three parts, each copied from the Rust crates (`rand_core`, `rand_pcg` and `rand`, version 0.9):

| Part | Rust | C# |
|---|---|---|
| seeding | `Pcg32::seed_from_u64(seed)` | [`Pcg32.FromSeed(seed)`](../procgen-csharp/Pcg32.cs#L27-L42) |
| next number | `rng.next_u32()` | [`NextU32()`](../procgen-csharp/Pcg32.cs#L44-L49) |
| number in a range | `rng.random_range(low..=high)` | [`RandomRange(low, high)`](../procgen-csharp/Pcg32.cs#L52-L76) |

## PCG32 in short

PCG ("permuted congruential generator") keeps a 64-bit **state**. Each step:

1. **advance** the state with a linear congruential step: `state = state × multiplier + increment` ([`Step`](../procgen-csharp/Pcg32.cs#L78-L81)),
2. **output** 32 bits made from the *old* state with the "XSH RR" function: shift and xor the high bits, then rotate by the top 5 bits ([`Output`](../procgen-csharp/Pcg32.cs#L84-L89)).

The multiplication and addition are meant to overflow. C# `ulong` arithmetic wraps around by default, which matches Rust's `wrapping_mul` / `wrapping_add`.

The `increment` must be odd and selects one of 2⁶³ independent streams.

## Seeding: `FromSeed` ([L27–42](../procgen-csharp/Pcg32.cs#L27-L42))

Rust's `seed_from_u64` doesn't use the seed as the state directly. It first expands the 64-bit seed into 16 bytes with a small built-in PCG (different constants, [L29–30](../procgen-csharp/Pcg32.cs#L29-L30)):

1. four times: advance the seed, output 32 bits ([L33–37](../procgen-csharp/Pcg32.cs#L33-L37)),
2. the first two outputs form the 64-bit state, the last two the increment ([L39–40](../procgen-csharp/Pcg32.cs#L39-L40)),
3. the increment is made odd with `| 1`, then the generator takes one step ([L41](../procgen-csharp/Pcg32.cs#L41), [constructor L12–17](../procgen-csharp/Pcg32.cs#L12-L17)).

This expansion is why seeds like 0 and 1, which have very few bits set, still give well-mixed starting states.

## Numbers in a range: `RandomRange` ([L52–76](../procgen-csharp/Pcg32.cs#L52-L76))

Turning a 32-bit random number into a number from `low` to `high` can be done in many ways, and each gives different results. To match Rust exactly, this copies `rand` 0.9's method for single samples (`sample_single_inclusive`, "Canon's method"):

1. `range = high − low + 1` ([L59](../procgen-csharp/Pcg32.cs#L59)).
2. Multiply a random 32-bit number by `range` as a 64-bit number. The **high** 32 bits are the result, from `0` to `range − 1` ([L60–62](../procgen-csharp/Pcg32.cs#L60-L62)).
3. The low 32 bits say how close the result was to rounding up. If they are very close, the result might be slightly biased, so a **second** random number is drawn to decide whether to round up ([L65–73](../procgen-csharp/Pcg32.cs#L65-L73)).
4. Return `low + result` ([L75](../procgen-csharp/Pcg32.cs#L75)).

Step 3 matters for determinism: it means one `RandomRange` call sometimes uses **two** random numbers. Any port that skips it would drift out of sync with Rust after the first time it happens. For small ranges like `8..=20` it is rare, for large ranges it happens more often; the verification covers both.

### Types

Rust's `random_range` behaves differently depending on the number type. The generator uses `i32` (sizes, positions, weights) and `usize` (room count). In `rand` 0.9 both are sampled with 32-bit numbers for ranges this small, so one C# method covers both. A 64-bit range (`i64`/`u64`) would need a 64-bit variant; nothing in the generator uses one.

`RandomRange` throws an `ArgumentException` for an empty range (`low > high`), where Rust panics.

## `FromStateAndStream` ([L20–23](../procgen-csharp/Pcg32.cs#L20-L23))

The same as Rust's `Pcg32::new(state, stream)`. The generator doesn't use it; it exists only to check the core algorithm against the official PCG test numbers (`state 42, stream 54`), see [Verification](verification.md).
