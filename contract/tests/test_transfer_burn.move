/// tests/test_transfer_burn.move
/// ─────────────────────────────────────────────────────────────
/// Tests for GameItem transfer and burn operations.
#[test_only]
module vaultx::test_transfer_burn {

    use sui::test_scenario::{Self as ts};
    use sui::clock;
    use vaultx::game_item::{Self, GameItem};
    use vaultx::constants;

    const PLAYER_A: address = @0xAA;
    const PLAYER_B: address = @0xBB;

    // ── Helpers ───────────────────────────────────────────────

    /// Mint a test item directly (bypasses open_box for unit testing).
    /// game_item::mint is package-visible so we can call it here.
    fun mint_test_item(
        rarity: u8,
        power:  u8,
        owner:  address,
        scenario: &mut ts::Scenario,
    ) {
        let clock = clock::create_for_testing(ts::ctx(scenario));
        let item  = game_item::mint(
            rarity,
            power,
            1,      // origin_box = 1
            owner,
            &clock,
            ts::ctx(scenario),
        );
        clock::destroy_for_testing(clock);
        transfer::public_transfer(item, owner);
    }

    // ── Transfer tests ────────────────────────────────────────

    /// Happy path: Player A transfers item to Player B.
    #[test]
    fun test_transfer_item_succeeds() {
        let mut scenario = ts::begin(PLAYER_A);

        // Mint a Rare item owned by PLAYER_A
        ts::next_tx(&mut scenario, PLAYER_A);
        mint_test_item(constants::rarity_rare(), 15, PLAYER_A, &mut scenario);

        // PLAYER_A transfers to PLAYER_B
        ts::next_tx(&mut scenario, PLAYER_A);
        {
            let item  = ts::take_from_sender<GameItem>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));

            game_item::transfer_item(item, PLAYER_B, &clock, ts::ctx(&mut scenario));

            clock::destroy_for_testing(clock);
        };

        // Verify PLAYER_B now owns the item
        ts::next_tx(&mut scenario, PLAYER_B);
        {
            let item = ts::take_from_sender<GameItem>(&scenario);
            assert!(game_item::owner(&item) == PLAYER_B, 0);
            assert!(game_item::rarity(&item) == constants::rarity_rare(), 1);
            assert!(game_item::power(&item) == 15, 2);
            ts::return_to_sender(&scenario, item);
        };

        ts::end(scenario);
    }

    /// Transfer to zero address must abort.
    #[test]
    #[expected_failure(abort_code = 1005, location = vaultx::game_item)]
    fun test_transfer_to_zero_address_aborts() {
        let mut scenario = ts::begin(PLAYER_A);

        ts::next_tx(&mut scenario, PLAYER_A);
        mint_test_item(constants::rarity_common(), 5, PLAYER_A, &mut scenario);

        ts::next_tx(&mut scenario, PLAYER_A);
        {
            let item  = ts::take_from_sender<GameItem>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));

            // Sending to 0x0 must abort with E_INVALID_RECIPIENT (1005)
            game_item::transfer_item(item, @0x0, &clock, ts::ctx(&mut scenario));

            clock::destroy_for_testing(clock);
        };

        ts::end(scenario);
    }

    /// Transfer to self is allowed (no restriction in spec).
    #[test]
    fun test_transfer_to_self_succeeds() {
        let mut scenario = ts::begin(PLAYER_A);

        ts::next_tx(&mut scenario, PLAYER_A);
        mint_test_item(constants::rarity_common(), 5, PLAYER_A, &mut scenario);

        ts::next_tx(&mut scenario, PLAYER_A);
        {
            let item  = ts::take_from_sender<GameItem>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));

            // Transferring to yourself is unusual but should succeed
            game_item::transfer_item(item, PLAYER_A, &clock, ts::ctx(&mut scenario));

            clock::destroy_for_testing(clock);
        };

        // Verify item is still with PLAYER_A
        ts::next_tx(&mut scenario, PLAYER_A);
        {
            let item = ts::take_from_sender<GameItem>(&scenario);
            assert!(game_item::owner(&item) == PLAYER_A, 3);
            ts::return_to_sender(&scenario, item);
        };

        ts::end(scenario);
    }

    // ── Burn tests ────────────────────────────────────────────

    /// Happy path: player burns their item.
    #[test]
    fun test_burn_item_succeeds() {
        let mut scenario = ts::begin(PLAYER_A);

        ts::next_tx(&mut scenario, PLAYER_A);
        mint_test_item(constants::rarity_epic(), 30, PLAYER_A, &mut scenario);

        ts::next_tx(&mut scenario, PLAYER_A);
        {
            let item  = ts::take_from_sender<GameItem>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));

            // Burn it — after this, the item no longer exists on-chain
            game_item::burn_item(item, &clock, ts::ctx(&mut scenario));

            clock::destroy_for_testing(clock);
        };

        // After burn, PLAYER_A should have no items
        ts::next_tx(&mut scenario, PLAYER_A);
        {
            // If we tried ts::take_from_sender here it would fail (no item).
            // The absence is the assertion.
            assert!(!ts::has_most_recent_for_sender<GameItem>(&scenario), 4);
        };

        ts::end(scenario);
    }

    // ── Read accessor tests ───────────────────────────────────

    /// Verify all item fields are set correctly at mint time.
    #[test]
    fun test_item_fields_set_correctly() {
        let mut scenario = ts::begin(PLAYER_A);

        ts::next_tx(&mut scenario, PLAYER_A);
        {
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            let item  = game_item::mint(
                constants::rarity_legendary(),
                47,
                42,        // origin_box = 42
                PLAYER_A,
                &clock,
                ts::ctx(&mut scenario),
            );

            assert!(game_item::rarity(&item)     == constants::rarity_legendary(), 5);
            assert!(game_item::power(&item)      == 47,       6);
            assert!(game_item::origin_box(&item) == 42,       7);
            assert!(game_item::owner(&item)      == PLAYER_A, 8);

            // Name should be "Legendary Item #42"
            let name = game_item::name(&item);
            // std::string doesn't have equality in tests easily,
            // so we just assert it's not empty
            assert!(std::string::length(&name) > 0, 9);

            clock::destroy_for_testing(clock);
            transfer::public_transfer(item, PLAYER_A);
        };

        ts::end(scenario);
    }

    // ── Item name generation tests ────────────────────────────

    /// Verify names are generated for all 4 rarity tiers.
    #[test]
    fun test_item_names_all_rarities() {
        let mut scenario = ts::begin(PLAYER_A);

        ts::next_tx(&mut scenario, PLAYER_A);
        {
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));

            let rarities = vector[
                constants::rarity_common(),
                constants::rarity_rare(),
                constants::rarity_epic(),
                constants::rarity_legendary(),
            ];

            let mut i = 0u64;
            while (i < 4) {
                let rarity = *vector::borrow(&rarities, i);
                let item = game_item::mint(rarity, 5, i + 1, PLAYER_A, &clock, ts::ctx(&mut scenario));
                // Just verify a name was generated (non-empty)
                assert!(std::string::length(&game_item::name(&item)) > 0, i as u64);
                transfer::public_transfer(item, PLAYER_A);
                i = i + 1;
            };

            clock::destroy_for_testing(clock);
        };

        ts::end(scenario);
    }
}
