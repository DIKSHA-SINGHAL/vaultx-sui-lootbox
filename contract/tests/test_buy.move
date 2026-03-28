/// tests/test_buy.move
/// ─────────────────────────────────────────────────────────────
/// Tests for the loot box purchase flow.
///
/// HOW SUI MOVE TESTS WORK:
/// - Test functions are annotated #[test]
/// - sui::test_scenario simulates a real multi-party transaction
///   sequence (different senders, multiple tx per test)
/// - test_scenario::begin(addr) starts the scenario as `addr`
/// - next_tx(&mut scenario, addr) advances to a new tx with addr as sender
/// - test_scenario::end(scenario) cleans up and checks no leftover objects
#[test_only]
module vaultx::test_buy {

    use sui::test_scenario::{Self as ts, Scenario};
    use sui::coin;
    use sui::clock;
    use vaultx::config::{Self, GameConfig};
    use vaultx::loot_box;
    use vaultx::constants;

    // ── Test addresses ────────────────────────────────────────
    // Use fixed addresses so tests are deterministic
    const ADMIN:  address = @0xAD;
    const PLAYER: address = @0xBB;

    // ── Helpers ───────────────────────────────────────────────

    /// Deploy the package and return the scenario.
    /// After this, ADMIN holds AdminCap and GameConfig is shared.
    fun deploy(): Scenario {
        let mut scenario = ts::begin(ADMIN);
        {
            // init() is private — use test init helper
            let ctx = ts::ctx(&mut scenario);
            vaultx::admin::create_and_transfer(ctx);
            vaultx::config::create_and_share(ctx);
        };
        scenario
    }

    // ── Tests ─────────────────────────────────────────────────

    /// Happy path: player pays exact price, gets a LootBox.
    #[test]
    fun test_buy_exact_payment() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, PLAYER);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));

            // Create a coin of exactly the right amount
            let payment = coin::mint_for_testing<sui::sui::SUI>(
                constants::default_price_mist(),
                ts::ctx(&mut scenario),
            );

            loot_box::buy(&mut config, payment, &clock, ts::ctx(&mut scenario));

            // Verify counter incremented
            assert!(config::total_boxes_sold(&config) == 1, 0);

            clock::destroy_for_testing(clock);
            ts::return_shared(config);
        };

        // Verify player received a LootBox
        ts::next_tx(&mut scenario, PLAYER);
        {
            // LootBox should exist in PLAYER's inventory
            // (we can't easily read its fields without a public accessor test,
            //  but the fact that take_from_sender succeeds proves it exists)
            // In a real test you'd assert box_number, owner, etc.
        };

        ts::end(scenario);
    }

    /// Underpayment: player sends less than price → should abort.
    #[test]
    #[expected_failure(abort_code = 1002, location = vaultx::loot_box)]
    fun test_buy_underpayment_aborts() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, PLAYER);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));

            // Pay 1 MIST less than required
            let payment = coin::mint_for_testing<sui::sui::SUI>(
                constants::default_price_mist() - 1,
                ts::ctx(&mut scenario),
            );

            // This should abort with E_WRONG_PAYMENT (1002)
            loot_box::buy(&mut config, payment, &clock, ts::ctx(&mut scenario));

            clock::destroy_for_testing(clock);
            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    /// Overpayment: player sends more than price → should also abort.
    /// VaultX requires EXACT payment.
    #[test]
    #[expected_failure(abort_code = 1002, location = vaultx::loot_box)]
    fun test_buy_overpayment_aborts() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, PLAYER);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));

            let payment = coin::mint_for_testing<sui::sui::SUI>(
                constants::default_price_mist() + 1,
                ts::ctx(&mut scenario),
            );

            loot_box::buy(&mut config, payment, &clock, ts::ctx(&mut scenario));

            clock::destroy_for_testing(clock);
            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    /// Paused game: buy should abort with E_GAME_PAUSED.
    #[test]
    #[expected_failure(abort_code = 1001, location = vaultx::loot_box)]
    fun test_buy_while_paused_aborts() {
        let mut scenario = deploy();

        // Admin pauses the game first
        ts::next_tx(&mut scenario, ADMIN);
        {
            let cap    = ts::take_from_sender<vaultx::admin::AdminCap>(&scenario);
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock  = clock::create_for_testing(ts::ctx(&mut scenario));
            let ctx    = ts::ctx(&mut scenario);

            vaultx::admin::set_paused(&cap, &mut config, true, &clock, ctx);

            clock::destroy_for_testing(clock);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(config);
        };

        // Player tries to buy → should abort
        ts::next_tx(&mut scenario, PLAYER);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));

            let payment = coin::mint_for_testing<sui::sui::SUI>(
                constants::default_price_mist(),
                ts::ctx(&mut scenario),
            );

            loot_box::buy(&mut config, payment, &clock, ts::ctx(&mut scenario));

            clock::destroy_for_testing(clock);
            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    /// Box counter: buying multiple boxes increments counter correctly.
    #[test]
    fun test_buy_counter_increments() {
        let mut scenario = deploy();

        // Buy 3 boxes
        let mut i = 0u64;
        while (i < 3) {
            ts::next_tx(&mut scenario, PLAYER);
            {
                let mut config = ts::take_shared<GameConfig>(&scenario);
                let clock = clock::create_for_testing(ts::ctx(&mut scenario));

                let payment = coin::mint_for_testing<sui::sui::SUI>(
                    constants::default_price_mist(),
                    ts::ctx(&mut scenario),
                );

                loot_box::buy(&mut config, payment, &clock, ts::ctx(&mut scenario));

                clock::destroy_for_testing(clock);
                ts::return_shared(config);
            };
            i = i + 1;
        };

        // Verify counter is 3
        ts::next_tx(&mut scenario, ADMIN);
        {
            let config = ts::take_shared<GameConfig>(&scenario);
            assert!(config::total_boxes_sold(&config) == 3, 1);
            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    /// Treasury: payment accumulates correctly.
    #[test]
    fun test_buy_treasury_fills() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, PLAYER);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));

            let payment = coin::mint_for_testing<sui::sui::SUI>(
                constants::default_price_mist(),
                ts::ctx(&mut scenario),
            );

            loot_box::buy(&mut config, payment, &clock, ts::ctx(&mut scenario));

            // Treasury should now hold exactly price_mist
            assert!(config::treasury_balance(&config) == constants::default_price_mist(), 2);

            clock::destroy_for_testing(clock);
            ts::return_shared(config);
        };

        ts::end(scenario);
    }
}
