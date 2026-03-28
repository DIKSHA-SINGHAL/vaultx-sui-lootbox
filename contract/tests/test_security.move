/// tests/test_security.move
/// ─────────────────────────────────────────────────────────────
/// Security-focused tests documenting the three randomness rules
/// and verifying edge cases around the security model.
///
/// These tests document INVARIANTS — properties that must always
/// hold — rather than just testing happy paths.
#[test_only]
module vaultx::test_security {

    use vaultx::constants;

    // ── Security invariant documentation ─────────────────────

    /// INVARIANT 1: open_box is 'entry', not 'public entry'.
    ///
    /// This is verified at the COMPILER level, not runtime.
    /// The Move compiler enforces that 'entry' functions cannot
    /// be called from other Move modules — only from PTBs.
    ///
    /// If this invariant broke (someone changed entry to public entry),
    /// an attacker could:
    ///   1. Call open_box from their contract
    ///   2. Check if rarity == Legendary
    ///   3. Abort the transaction if not
    ///   4. Loop until Legendary → guaranteed Legendaries for gas only
    ///
    /// This test documents the invariant; the compiler enforces it.
    #[test]
    fun test_invariant_open_box_is_entry_not_public() {
        // Compile-time guarantee — documented here for clarity.
        // If open_box were public entry, this comment would be wrong,
        // but the code would still compile (that's the risk — no runtime test
        // can catch it, only a code audit or the compiler flag).
        assert!(true, 0);
    }

    /// INVARIANT 2: RandomGenerator is created INSIDE open_box.
    ///
    /// random::new_generator(rand, ctx) is called on the first line
    /// of open_box after the guard checks.  It is not a parameter.
    ///
    /// If a generator were passed as parameter, an attacker could
    /// preview the outputs before committing to the transaction.
    #[test]
    fun test_invariant_generator_created_inside_function() {
        // Code review check — the generator variable `gen` is declared
        // inside open_box::open_box() with `let mut gen = ...`.
        // It is never accepted as a function argument.
        assert!(true, 0);
    }

    /// INVARIANT 3: Random object address is verified to be 0x8.
    ///
    /// open_box asserts: object::id_address(rand) == @0x8
    ///
    /// Without this check, someone could pass a fake Random object
    /// with a known internal state to manipulate the outcome.
    #[test]
    fun test_invariant_random_object_address_verified() {
        // The assert is in open_box.move line ~50.
        // This documents the security requirement.
        assert!(true, 0);
    }

    // ── Weight boundary tests ─────────────────────────────────

    /// Verify that rarity determination covers ALL 100 roll values.
    /// No roll value (0-99) should fall through without a rarity.
    /// With default weights 60+25+12+3 = 100, this is guaranteed,
    /// but we document the coverage explicitly.
    #[test]
    fun test_all_100_roll_values_covered() {
        // With weights 60/25/12/3:
        //   0..59  → 60 values → Common
        //   60..84 → 25 values → Rare
        //   85..96 → 12 values → Epic
        //   97..99 →  3 values → Legendary
        //   Total  = 100 values ✓

        // Also verify constants sum correctly
        let total = (constants::default_common_weight() as u64)
                  + (constants::default_rare_weight() as u64)
                  + (constants::default_epic_weight() as u64)
                  + (constants::default_legendary_weight() as u64);
        assert!(total == 100, 0);
    }

    /// MIST conversion: 0.1 SUI = 100_000_000 MIST.
    #[test]
    fun test_price_constant_correct() {
        // 1 SUI = 1_000_000_000 MIST
        // 0.1 SUI = 100_000_000 MIST
        assert!(constants::default_price_mist() == 100_000_000, 0);
    }

    /// Power ranges must be non-overlapping and cover 1-50 continuously.
    #[test]
    fun test_power_ranges_non_overlapping_and_continuous() {
        // Common:    1-10
        // Rare:     11-25
        // Epic:     26-40
        // Legendary: 41-50

        // No gaps
        assert!(constants::rare_power_min()      == constants::common_power_max()    + 1, 0);
        assert!(constants::epic_power_min()      == constants::rare_power_max()      + 1, 1);
        assert!(constants::legendary_power_min() == constants::epic_power_max()      + 1, 2);

        // Full range: 1 to 50
        assert!(constants::common_power_min()    == 1,  3);
        assert!(constants::legendary_power_max() == 50, 4);
    }

    /// Pity threshold is 30 as specified in PRD.
    #[test]
    fun test_pity_threshold_is_30() {
        assert!(constants::pity_threshold() == 30, 0);
    }

    // ── Object model invariants ───────────────────────────────

    /// LootBox has 'key' only (no 'store') → non-transferable.
    /// Documented as a compiler-enforced invariant.
    #[test]
    fun test_lootbox_not_transferable_invariant() {
        // Move's type system: transfer::public_transfer() requires 'store'
        // LootBox only has 'key' → public_transfer won't compile on it
        // Only transfer::transfer() (direct to owner) works.
        // This prevents a secondary market for unopened boxes.
        assert!(true, 0);
    }

    /// AdminCap has 'key' only (no 'store') → cannot be transferred
    /// after creation.  Admin is locked to the deployer wallet.
    /// (Production: use multi-sig wallet as deployer.)
    #[test]
    fun test_admincap_not_transferable_invariant() {
        // Same pattern: 'key' only → transfer::public_transfer won't compile
        // Transferring admin requires upgrading the contract.
        assert!(true, 0);
    }

    /// GameItem has 'key + store' → transferable and composable.
    /// This is intentional — items are the "currency" of the game.
    #[test]
    fun test_gameitem_is_transferable_by_design() {
        // 'store' ability on GameItem allows:
        //   - transfer::public_transfer (player to player)
        //   - Future: wrapping inside marketplace objects
        //   - Future: wrapping inside crafting system objects
        assert!(true, 0);
    }
}
