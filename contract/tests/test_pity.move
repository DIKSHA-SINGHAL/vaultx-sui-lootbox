/// tests/test_pity.move
/// ─────────────────────────────────────────────────────────────
/// Tests for the pity system (dynamic fields on GameConfig).
///
/// PITY RULES:
///   - Counter starts at 0 for every player
///   - Each non-Legendary open increments boxes_opened
///   - At boxes_opened >= 30: pity_active flips to true
///   - Next open with pity_active: Legendary forced, counter reset
///   - Any Legendary (luck or pity): counter resets to 0
#[test_only]
module vaultx::test_pity {

    use sui::test_scenario::{Self as ts};
    use vaultx::config::GameConfig;
    use vaultx::pity;
    use vaultx::constants;

    const ADMIN:    address = @0xAD;
    const PLAYER_A: address = @0xAA;
    const PLAYER_B: address = @0xBB;

    fun deploy(): ts::Scenario {
        let mut scenario = ts::begin(ADMIN);
        {
            let ctx = ts::ctx(&mut scenario);
            vaultx::admin::create_and_transfer(ctx);
            vaultx::config::create_and_share(ctx);
        };
        scenario
    }

    // ── Initial state ─────────────────────────────────────────

    /// Player with no opens: pity should not be active.
    #[test]
    fun test_pity_not_active_for_new_player() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let config = ts::take_shared<GameConfig>(&scenario);

            // No dynamic field exists yet for PLAYER_A
            assert!(!pity::is_pity_active(&config, PLAYER_A), 0);
            assert!(pity::boxes_opened_count(&config, PLAYER_A) == 0, 1);

            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    // ── Accumulation ──────────────────────────────────────────

    /// Opening non-Legendary boxes increments the counter.
    #[test]
    fun test_pity_counter_accumulates() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);

            // Simulate 5 non-Legendary opens
            let mut i = 0u8;
            while (i < 5) {
                pity::record_open(&mut config, PLAYER_A, constants::rarity_common());
                i = i + 1;
            };

            assert!(pity::boxes_opened_count(&config, PLAYER_A) == 5, 0);
            assert!(!pity::is_pity_active(&config, PLAYER_A), 1);

            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    /// Rare and Epic also increment the counter (anything non-Legendary).
    #[test]
    fun test_pity_increments_on_rare_and_epic() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);

            pity::record_open(&mut config, PLAYER_A, constants::rarity_common());
            pity::record_open(&mut config, PLAYER_A, constants::rarity_rare());
            pity::record_open(&mut config, PLAYER_A, constants::rarity_epic());

            // All three non-Legendary → counter = 3
            assert!(pity::boxes_opened_count(&config, PLAYER_A) == 3, 0);

            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    // ── Threshold activation ──────────────────────────────────

    /// At exactly 30 non-Legendary opens, pity_active flips to true.
    #[test]
    fun test_pity_activates_at_threshold() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let threshold  = constants::pity_threshold();

            // Open threshold - 1 times → pity should NOT be active yet
            let mut i = 0u32;
            while (i < threshold - 1) {
                pity::record_open(&mut config, PLAYER_A, constants::rarity_common());
                i = i + 1;
            };
            assert!(!pity::is_pity_active(&config, PLAYER_A), 0);
            assert!(pity::boxes_opened_count(&config, PLAYER_A) == threshold - 1, 1);

            // One more non-Legendary → should activate pity
            pity::record_open(&mut config, PLAYER_A, constants::rarity_common());
            assert!(pity::is_pity_active(&config, PLAYER_A), 2);
            assert!(pity::boxes_opened_count(&config, PLAYER_A) == threshold, 3);

            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    // ── Reset on Legendary ────────────────────────────────────

    /// Getting a Legendary (by luck) resets counter immediately.
    #[test]
    fun test_pity_resets_on_lucky_legendary() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);

            // Open 10 common boxes
            let mut i = 0u8;
            while (i < 10) {
                pity::record_open(&mut config, PLAYER_A, constants::rarity_common());
                i = i + 1;
            };
            assert!(pity::boxes_opened_count(&config, PLAYER_A) == 10, 0);

            // Lucky Legendary → reset
            pity::record_open(&mut config, PLAYER_A, constants::rarity_legendary());
            assert!(pity::boxes_opened_count(&config, PLAYER_A) == 0, 1);
            assert!(!pity::is_pity_active(&config, PLAYER_A), 2);

            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    /// Pity triggers Legendary → counter resets to 0.
    #[test]
    fun test_pity_resets_after_pity_legendary() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let threshold  = constants::pity_threshold();

            // Reach threshold
            let mut i = 0u32;
            while (i < threshold) {
                pity::record_open(&mut config, PLAYER_A, constants::rarity_common());
                i = i + 1;
            };
            assert!(pity::is_pity_active(&config, PLAYER_A), 0);

            // Pity triggers a Legendary → record it
            pity::record_open(&mut config, PLAYER_A, constants::rarity_legendary());

            // Counter and flag must both be reset
            assert!(pity::boxes_opened_count(&config, PLAYER_A) == 0, 1);
            assert!(!pity::is_pity_active(&config, PLAYER_A), 2);

            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    // ── Per-player isolation ──────────────────────────────────

    /// Pity counters are per-wallet. PLAYER_A's counter doesn't
    /// affect PLAYER_B's counter.
    #[test]
    fun test_pity_is_per_player() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let threshold  = constants::pity_threshold();

            // PLAYER_A reaches pity threshold
            let mut i = 0u32;
            while (i < threshold) {
                pity::record_open(&mut config, PLAYER_A, constants::rarity_common());
                i = i + 1;
            };

            // PLAYER_B has zero opens
            assert!(pity::is_pity_active(&config, PLAYER_A), 0);
            assert!(!pity::is_pity_active(&config, PLAYER_B), 1);
            assert!(pity::boxes_opened_count(&config, PLAYER_B) == 0, 2);

            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    // ── Counter continues after reset ─────────────────────────

    /// After a reset, counter correctly accumulates again from 0.
    #[test]
    fun test_pity_reaccumulates_after_reset() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);

            // Open 15 common, get lucky Legendary, open 5 more common
            let mut i = 0u8;
            while (i < 15) {
                pity::record_open(&mut config, PLAYER_A, constants::rarity_common());
                i = i + 1;
            };

            pity::record_open(&mut config, PLAYER_A, constants::rarity_legendary()); // reset

            let mut j = 0u8;
            while (j < 5) {
                pity::record_open(&mut config, PLAYER_A, constants::rarity_common());
                j = j + 1;
            };

            // Should be at 5, not 20 (reset worked)
            assert!(pity::boxes_opened_count(&config, PLAYER_A) == 5, 0);
            assert!(!pity::is_pity_active(&config, PLAYER_A), 1);

            ts::return_shared(config);
        };

        ts::end(scenario);
    }
}
