/// constants.move
/// ─────────────────────────────────────────────────────────────
/// All numeric constants used across the VaultX package.
///
/// WHY A SEPARATE CONSTANTS MODULE?
/// Move doesn't have a preprocessor or #define.  Without this,
/// magic numbers (0, 1, 2, 3, 60, 25…) scatter across files
/// and become impossible to audit.  Centralising them means:
///   - One grep to find every usage of RARITY_LEGENDARY
///   - Changing PITY_THRESHOLD for an event is a single edit
///   - Tests can import these instead of duplicating literals
module vaultx::constants {

    // ── Rarity tier IDs ───────────────────────────────────────
    // Stored as u8 in GameItem.rarity and used as the dynamic-field
    // key discriminant.  Frontend maps: 0→grey, 1→blue, 2→purple, 3→gold.
    public fun rarity_common(): u8    { 0 }
    public fun rarity_rare(): u8      { 1 }
    public fun rarity_epic(): u8      { 2 }
    public fun rarity_legendary(): u8 { 3 }

    // ── Power ranges per tier ─────────────────────────────────
    // A second independent random roll after rarity is decided
    // picks the exact power within [min, max] inclusive.
    public fun common_power_min(): u8    { 1  }
    public fun common_power_max(): u8    { 10 }
    public fun rare_power_min(): u8      { 11 }
    public fun rare_power_max(): u8      { 25 }
    public fun epic_power_min(): u8      { 26 }
    public fun epic_power_max(): u8      { 40 }
    public fun legendary_power_min(): u8 { 41 }
    public fun legendary_power_max(): u8 { 50 }

    // ── Default rarity weights ────────────────────────────────
    // These must always sum to 100.
    // The roll is 0-99; each weight is how many of those 100 values
    // map to that tier.
    public fun default_common_weight(): u8    { 60 }
    public fun default_rare_weight(): u8      { 25 }
    public fun default_epic_weight(): u8      { 12 }
    public fun default_legendary_weight(): u8 { 3  }

    // ── Default price ─────────────────────────────────────────
    // Sui uses MIST (smallest unit): 1 SUI = 1_000_000_000 MIST.
    // 100_000_000 MIST = 0.1 SUI.
    public fun default_price_mist(): u64 { 100_000_000 }

    // ── Pity system ───────────────────────────────────────────
    // After this many consecutive non-Legendary opens, the next
    // open is guaranteed Legendary regardless of the random roll.
    public fun pity_threshold(): u32 { 30 }

    // ── Sui system object addresses ───────────────────────────
    // These are fixed protocol addresses — same on every Sui network.
    // We store them as u256 because Move addresses are 32 bytes.
    // Checked at runtime in open_box to prevent fake objects.
    //
    // 0x6 = Clock (global on-chain clock)
    // 0x8 = Random (distributed randomness beacon)
    //
    // NOTE: address literals are written as @0x6 / @0x8 in the
    // calling code; we expose numeric constants here for documentation.
    public fun random_object_id(): u256 { 8 }
}
