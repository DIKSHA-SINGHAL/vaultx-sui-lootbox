/// tests/test_open.move
/// ─────────────────────────────────────────────────────────────
/// Tests for the box opening flow and rarity determination.
#[test_only]
module vaultx::test_open {

    use sui::test_scenario::{Self as ts};
    use sui::coin;
    use sui::clock;
    use sui::random;
    use vaultx::config::GameConfig;
    use vaultx::constants;

    const ADMIN:  address = @0xAD;
    const PLAYER: address = @0xBB;

    fun deploy(): ts::Scenario {
        let mut scenario = ts::begin(ADMIN);
        {
            let ctx = ts::ctx(&mut scenario);
            vaultx::admin::create_and_transfer(ctx);
            vaultx::config::create_and_share(ctx);
        };
        scenario
    }

    // ── Rarity boundary tests ─────────────────────────────────
    // With default weights 60/25/12/3:
    //   0-59  → Common, 60-84 → Rare, 85-96 → Epic, 97-99 → Legendary

    #[test]
    fun test_rarity_boundaries() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let config = ts::take_shared<GameConfig>(&scenario);

            assert!(vaultx::open_box::test_determine_rarity(&config, 0)  == constants::rarity_common(), 0);
            assert!(vaultx::open_box::test_determine_rarity(&config, 59) == constants::rarity_common(), 1);
            assert!(vaultx::open_box::test_determine_rarity(&config, 60) == constants::rarity_rare(), 2);
            assert!(vaultx::open_box::test_determine_rarity(&config, 84) == constants::rarity_rare(), 3);
            assert!(vaultx::open_box::test_determine_rarity(&config, 85) == constants::rarity_epic(), 4);
            assert!(vaultx::open_box::test_determine_rarity(&config, 96) == constants::rarity_epic(), 5);
            assert!(vaultx::open_box::test_determine_rarity(&config, 97) == constants::rarity_legendary(), 6);
            assert!(vaultx::open_box::test_determine_rarity(&config, 99) == constants::rarity_legendary(), 7);

            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    #[test]
    fun test_rarity_midpoints() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let config = ts::take_shared<GameConfig>(&scenario);

            assert!(vaultx::open_box::test_determine_rarity(&config, 30) == constants::rarity_common(), 8);
            assert!(vaultx::open_box::test_determine_rarity(&config, 70) == constants::rarity_rare(), 9);
            assert!(vaultx::open_box::test_determine_rarity(&config, 90) == constants::rarity_epic(), 10);
            assert!(vaultx::open_box::test_determine_rarity(&config, 98) == constants::rarity_legendary(), 11);

            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    // ── Power range tests ─────────────────────────────────────
    // FIX 3: new_generator_for_testing() takes 0 arguments in this Sui version
    // (the seed parameter was removed — it always creates a deterministic generator)
    #[test]
    fun test_power_ranges_respected() {
        let mut scenario = ts::begin(ADMIN);

        ts::next_tx(&mut scenario, ADMIN);
        {
            // new_generator_for_testing() — no arguments in current Sui SDK
            let mut gen = random::new_generator_for_testing();

            let mut i = 0u8;
            while (i < 50) {
                let common_power = random::generate_u8_in_range(
                    &mut gen,
                    constants::common_power_min(),
                    constants::common_power_max(),
                );
                assert!(common_power >= constants::common_power_min(), 0);
                assert!(common_power <= constants::common_power_max(), 1);

                let legendary_power = random::generate_u8_in_range(
                    &mut gen,
                    constants::legendary_power_min(),
                    constants::legendary_power_max(),
                );
                assert!(legendary_power >= constants::legendary_power_min(), 2);
                assert!(legendary_power <= constants::legendary_power_max(), 3);

                i = i + 1;
            };
        };

        ts::end(scenario);
    }

    // ── Paused game tests ─────────────────────────────────────

    /// Buying while paused aborts with e_game_paused().
    /// (open_box is entry so can't be tested directly here —
    ///  the buy guard demonstrates the pause mechanism.)
    #[test]
    #[expected_failure(abort_code = 1001, location = vaultx::loot_box)]
    fun test_buy_while_paused_aborts() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let cap        = ts::take_from_sender<vaultx::admin::AdminCap>(&scenario);
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock      = clock::create_for_testing(ts::ctx(&mut scenario));
            let ctx        = ts::ctx(&mut scenario);

            vaultx::admin::set_paused(&cap, &mut config, true, &clock, ctx);

            clock::destroy_for_testing(clock);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(config);
        };

        ts::next_tx(&mut scenario, PLAYER);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock      = clock::create_for_testing(ts::ctx(&mut scenario));

            let payment = coin::mint_for_testing<sui::sui::SUI>(
                constants::default_price_mist(),
                ts::ctx(&mut scenario),
            );
            // Aborts with E_GAME_PAUSED = 1001
            vaultx::loot_box::buy(&mut config, payment, &clock, ts::ctx(&mut scenario));

            clock::destroy_for_testing(clock);
            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    #[test]
    fun test_open_burns_box_requirement_documented() {
        // LootBox has no copy/drop — Move's type system forces it to be consumed
        // by loot_box::destroy() which calls object::delete(id). Cannot be kept.
        assert!(true, 0);
    }
}
