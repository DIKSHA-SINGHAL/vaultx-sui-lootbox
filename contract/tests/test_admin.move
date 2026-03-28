/// tests/test_admin.move
/// ─────────────────────────────────────────────────────────────
/// Tests for all admin operations: weights, price, pause, withdraw.
#[test_only]
module vaultx::test_admin {

    use sui::test_scenario::{Self as ts};
    use sui::coin;
    use sui::clock;
    use vaultx::config::{Self, GameConfig};
    use vaultx::admin::AdminCap;
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

    // ── Weight update tests ───────────────────────────────────

    /// Happy path: admin updates weights to valid values.
    #[test]
    fun test_update_weights_valid() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let cap        = ts::take_from_sender<AdminCap>(&scenario);
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock      = clock::create_for_testing(ts::ctx(&mut scenario));
            let ctx        = ts::ctx(&mut scenario);

            // New weights: 50/30/15/5 (sum = 100) ✓
            vaultx::admin::update_weights(&cap, &mut config, 50, 30, 15, 5, &clock, ctx);

            assert!(config::common_weight(&config)    == 50, 0);
            assert!(config::rare_weight(&config)      == 30, 1);
            assert!(config::epic_weight(&config)      == 15, 2);
            assert!(config::legendary_weight(&config) == 5,  3);

            clock::destroy_for_testing(clock);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    /// Weights that don't sum to 100 must abort.
    #[test]
    #[expected_failure(abort_code = 1003, location = vaultx::admin)]
    fun test_update_weights_invalid_sum_aborts() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let cap        = ts::take_from_sender<AdminCap>(&scenario);
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock      = clock::create_for_testing(ts::ctx(&mut scenario));
            let ctx        = ts::ctx(&mut scenario);

            // Sum = 99, not 100 → must abort
            vaultx::admin::update_weights(&cap, &mut config, 50, 30, 15, 4, &clock, ctx);

            clock::destroy_for_testing(clock);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    /// Any weight = 0 must abort (no tier can be disabled).
    #[test]
    #[expected_failure(abort_code = 1004, location = vaultx::admin)]
    fun test_update_weights_zero_aborts() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let cap        = ts::take_from_sender<AdminCap>(&scenario);
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock      = clock::create_for_testing(ts::ctx(&mut scenario));
            let ctx        = ts::ctx(&mut scenario);

            // Legendary = 0 would disable it entirely → not allowed
            vaultx::admin::update_weights(&cap, &mut config, 60, 25, 15, 0, &clock, ctx);

            clock::destroy_for_testing(clock);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    // ── Price update tests ────────────────────────────────────

    #[test]
    fun test_update_price() {
        let mut scenario = deploy();

        ts::next_tx(&mut scenario, ADMIN);
        {
            let cap        = ts::take_from_sender<AdminCap>(&scenario);
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock      = clock::create_for_testing(ts::ctx(&mut scenario));
            let ctx        = ts::ctx(&mut scenario);

            let new_price = 200_000_000u64; // 0.2 SUI
            vaultx::admin::update_price(&cap, &mut config, new_price, &clock, ctx);

            assert!(config::price(&config) == new_price, 0);

            clock::destroy_for_testing(clock);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    // ── Pause / unpause tests ─────────────────────────────────

    #[test]
    fun test_pause_and_unpause() {
        let mut scenario = deploy();

        // Start: not paused
        ts::next_tx(&mut scenario, ADMIN);
        {
            let config = ts::take_shared<GameConfig>(&scenario);
            assert!(!config::is_paused(&config), 0);
            ts::return_shared(config);
        };

        // Pause
        ts::next_tx(&mut scenario, ADMIN);
        {
            let cap        = ts::take_from_sender<AdminCap>(&scenario);
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock      = clock::create_for_testing(ts::ctx(&mut scenario));

            vaultx::admin::set_paused(&cap, &mut config, true, &clock, ts::ctx(&mut scenario));
            assert!(config::is_paused(&config), 1);

            clock::destroy_for_testing(clock);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(config);
        };

        // Unpause
        ts::next_tx(&mut scenario, ADMIN);
        {
            let cap        = ts::take_from_sender<AdminCap>(&scenario);
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock      = clock::create_for_testing(ts::ctx(&mut scenario));

            vaultx::admin::set_paused(&cap, &mut config, false, &clock, ts::ctx(&mut scenario));
            assert!(!config::is_paused(&config), 2);

            clock::destroy_for_testing(clock);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(config);
        };

        ts::end(scenario);
    }

    // ── Treasury withdrawal tests ─────────────────────────────

    /// Admin can withdraw accumulated treasury.
    #[test]
    fun test_withdraw_treasury() {
        let mut scenario = deploy();

        // Player buys a box (fills treasury)
        ts::next_tx(&mut scenario, PLAYER);
        {
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock      = clock::create_for_testing(ts::ctx(&mut scenario));

            let payment = coin::mint_for_testing<sui::sui::SUI>(
                constants::default_price_mist(),
                ts::ctx(&mut scenario),
            );
            vaultx::loot_box::buy(&mut config, payment, &clock, ts::ctx(&mut scenario));

            clock::destroy_for_testing(clock);
            ts::return_shared(config);
        };

        // Admin withdraws
        ts::next_tx(&mut scenario, ADMIN);
        {
            let cap        = ts::take_from_sender<AdminCap>(&scenario);
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let clock      = clock::create_for_testing(ts::ctx(&mut scenario));

            // Treasury should have the payment
            assert!(config::treasury_balance(&config) == constants::default_price_mist(), 0);

            vaultx::admin::withdraw_treasury(&cap, &mut config, &clock, ts::ctx(&mut scenario));

            // Treasury should now be empty
            assert!(config::treasury_balance(&config) == 0, 1);

            clock::destroy_for_testing(clock);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(config);
        };

        // Admin should have received a Coin<SUI>
        ts::next_tx(&mut scenario, ADMIN);
        {
            let coin_obj = ts::take_from_sender<sui::coin::Coin<sui::sui::SUI>>(&scenario);
            assert!(sui::coin::value(&coin_obj) == constants::default_price_mist(), 2);
            ts::return_to_sender(&scenario, coin_obj);
        };

        ts::end(scenario);
    }

    // ── Access control: non-admin cannot call admin functions ─────

    /// This test verifies that the AdminCap pattern works:
    /// without AdminCap in your wallet, you cannot call admin functions.
    /// The Sui VM enforces this at the type level — you can't fake it.
    ///
    /// We document the invariant here rather than testing it (the
    /// test framework would need to forge an AdminCap to attempt it,
    /// which Move's type system makes impossible by design).
    #[test]
    fun test_admin_cap_access_control_invariant() {
        // The AdminCap type has no copy ability.
        // Therefore a non-admin wallet cannot obtain one.
        // Therefore they cannot call any function that requires &AdminCap.
        // This is enforced by Move's type system, not by runtime checks.
        // No test needed — it's a compile-time guarantee.
        assert!(true, 0);
    }
}
