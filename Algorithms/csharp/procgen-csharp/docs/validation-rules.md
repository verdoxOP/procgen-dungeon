# Validation rules

[← Documentation home](README.md)

The rules, their origin in the brainstorm document and the full list (VR, BV, CV, PV) are in [Rust → Validation rules](../../../rust/procgen_dungeon/docs/validation-rules.md). This page only shows what the C# generator implements so far.

## VR: room validation

| Rule | Description | Status | Code |
|---|---|---|---|
| VR-01 | rooms must be at least a minimum size | ✅ | [`Validation.cs` L15–22](../procgen-csharp/Validation.cs#L15-L22) |
| VR-02 | rooms are not allowed to overlap | ✅ | [`Validation.cs` L24–34](../procgen-csharp/Validation.cs#L24-L34), [`Room.Overlaps`](../procgen-csharp/Room.cs#L13-L24) |
| VR-03 | at least N rooms must be successfully generated | ✅ | [`Validation.cs` L9–13](../procgen-csharp/Validation.cs#L9-L13) |
| VR-04 | minimum room width and height must be configurable | ✅ | [`Constants.cs` L13–14](../procgen-csharp/Constants.cs#L13-L14) |

On failure the whole room set is regenerated with the same RNG, up to `MaxGenerationAttempts` times ([`Program.cs` L18–23](../procgen-csharp/Program.cs#L18-L23)). If it is still invalid, the program exits with code 1 ([L25–29](../procgen-csharp/Program.cs#L25-L29)).

The checks run in the same order as in Rust and stop at the first failure. The order doesn't affect the dungeon (validation draws no random numbers), only which reason is printed.

## Other stages

| Prefix | Stage | C# status |
|---|---|---|
| BV | backbone validation | ⏳ after the backbone (Prim) is ported |
| CV | corridor validation | ⏳ after corridors exist in Rust |
| PV | population validation | ⏳ after population exists in Rust |
