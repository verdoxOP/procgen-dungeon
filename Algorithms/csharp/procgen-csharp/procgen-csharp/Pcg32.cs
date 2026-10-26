namespace procgen_csharp;

// Seeded random number generator, a port of Rust's rand_pcg::Pcg32 (rand 0.9),
// so the same seed gives exactly the same numbers as the Rust generator.
public class Pcg32
{
    private const ulong Multiplier = 6364136223846793005;

    private ulong _state;
    private readonly ulong _increment;

    private Pcg32(ulong state, ulong increment)
    {
        _increment = increment;
        _state = state + increment;
        Step();
    }

    // Pcg32::new(state, stream) in Rust. Only used to check against the official PCG test numbers.
    public static Pcg32 FromStateAndStream(ulong state, ulong stream)
    {
        return new Pcg32(state, (stream << 1) | 1);
    }

    // Pcg32::seed_from_u64(seed) in Rust: turns the seed into 16 bytes with a small PCG,
    // the first 8 bytes become the state and the last 8 the increment.
    public static Pcg32 FromSeed(ulong seed)
    {
        const ulong seedMultiplier = 0x5851F42D4C957F2D;
        const ulong seedIncrement = 0xA17654E46FBE17F3;

        var words = new uint[4];
        for (int i = 0; i < words.Length; i++)
        {
            seed = seed * seedMultiplier + seedIncrement;
            words[i] = Output(seed);
        }

        ulong state = words[0] | ((ulong)words[1] << 32);
        ulong increment = words[2] | ((ulong)words[3] << 32);
        return new Pcg32(state, increment | 1);
    }

    public uint NextU32()
    {
        ulong oldState = _state;
        Step();
        return Output(oldState);
    }

    // rng.random_range(low..=high) in Rust for i32 and usize (both use 32 bit sampling for our ranges).
    public int RandomRange(int low, int high)
    {
        if (low > high)
        {
            throw new ArgumentException($"Empty range {low}..={high}");
        }

        uint range = (uint)(high - low + 1);
        ulong product = (ulong)NextU32() * range;
        uint result = (uint)(product >> 32);
        uint lowOrder = (uint)product;

        // The first sample can be slightly biased, a second one decides whether to round up.
        if (lowOrder > unchecked(0u - range))
        {
            uint newHighOrder = (uint)(((ulong)NextU32() * range) >> 32);
            bool overflow = (ulong)lowOrder + newHighOrder > uint.MaxValue;
            if (overflow)
            {
                result++;
            }
        }

        return unchecked(low + (int)result);
    }

    private void Step()
    {
        _state = _state * Multiplier + _increment;
    }

    // The PCG "XSH RR" output function: xorshift the high bits, then rotate by the top 5 bits.
    private static uint Output(ulong state)
    {
        uint xorShifted = (uint)(((state >> 18) ^ state) >> 27);
        int rotation = (int)(state >> 59);
        return (xorShifted >> rotation) | (xorShifted << (-rotation & 31));
    }
}
