/// open_box.move
/// ─────────────────────────────────────────────────────────────
/// The open_box entry function — the most security-critical piece
/// of the entire VaultX package.
///
/// THREE MANDATORY SECURITY RULES (PRD section 5):
///
/// RULE 1 — entry, NOT public entry
///   'entry' blocks other contracts from calling open_box.
///   Without it an attacker can call open_box, check if rarity==Legendary,
///   abort if not, and loop until Legendary — free Legendaries for gas.
///
/// RULE 2 — RandomGenerator created INSIDE this function
///   Born here, used here, dies here. Never a parameter.
///   If passed in, attacker previews outputs before committing.
///
/// RULE 3 — Verify Random object is at address 0x8
///   Guards against a fake Random object with predictable outputs.
module vaultx::open_box {

    use sui::random::{Self, Random};
    use sui::clock::{Self, Clock};
    use vaultx::config::{Self, GameConfig};
    use vaultx::loot_box::LootBox;
    use vaultx::game_item;
    use vaultx::pity;
    use vaultx::errors;
    use vaultx::events;
    use vaultx::constants;

    // ── Entry function ────────────────────────────────────────
    /// ⚠ MUST be `entry` not `public entry` — see RULE 1 above.
    entry fun open_box(
        config:   &mut GameConfig,
        loot_box: LootBox,
        rand:     &Random,
        clock:    &Clock,
        ctx:      &mut TxContext,
    ) {
        // Guard: game must not be paused
        assert!(!config::is_paused(config), errors::e_game_paused());

        // RULE 3: Verify the Random object is really Sui's beacon at 0x8
        assert!(
            object::id_address(rand) == @0x8,
            errors::e_invalid_random_object()
        );

        let player = tx_context::sender(ctx);
        let now_ms = clock::timestamp_ms(clock);

        // Check pity BEFORE rolling — pity overrides the roll entirely
        let pity_triggered = pity::is_pity_active(config, player);

        // RULE 2: RandomGenerator created INSIDE this function, never a parameter
        let mut gen = random::new_generator(rand, ctx);

        // Roll 0-99 (100 possible values = sum of all weights)
        let raw_roll = random::generate_u8_in_range(&mut gen, 0, 99);

        // Determine rarity — pity forces Legendary, otherwise use the roll
        let rarity = if (pity_triggered) {
            constants::rarity_legendary()
        } else {
            determine_rarity(config, raw_roll)
        };

        // Second independent roll: power level within the tier's range
        let power = roll_power(&mut gen, rarity);

        // Capture box data BEFORE destroying the LootBox object
        let box_id = object::id(&loot_box);
        let (origin_box, _buyer) = vaultx::loot_box::destroy(loot_box);

        // Mint the GameItem NFT
        let item = game_item::mint(rarity, power, origin_box, player, clock, ctx);
        let item_id = object::id(&item);

        // Update pity tracker AFTER rarity is finalised
        pity::record_open(config, player, rarity);

        // Emit event BEFORE transfer (raw_roll published for verifiability)
        events::emit_box_opened(box_id, item_id, rarity, power, player, raw_roll, pity_triggered, now_ms);

        // FIX 1: GameItem has 'store' ability → must use public_transfer, not transfer
        // transfer::transfer() is restricted to the object's own module (game_item.move)
        // transfer::public_transfer() is for objects with 'store' called from any module
        transfer::public_transfer(item, player);
    }

    // ── Rarity determination ──────────────────────────────────
    /// Maps roll (0-99) to rarity using live weights from GameConfig.
    /// Ranges shift automatically if admin updates weights.
    fun determine_rarity(config: &GameConfig, roll: u8): u8 {
        let common = config::common_weight(config);
        let rare   = config::rare_weight(config);
        let epic   = config::epic_weight(config);

        if (roll < common) {
            constants::rarity_common()
        } else if (roll < common + rare) {
            constants::rarity_rare()
        } else if (roll < common + rare + epic) {
            constants::rarity_epic()
        } else {
            constants::rarity_legendary()
        }
    }

    /// Rolls a power value within the tier's min-max range.
    fun roll_power(gen: &mut random::RandomGenerator, rarity: u8): u8 {
        if (rarity == constants::rarity_common()) {
            random::generate_u8_in_range(gen, constants::common_power_min(), constants::common_power_max())
        } else if (rarity == constants::rarity_rare()) {
            random::generate_u8_in_range(gen, constants::rare_power_min(), constants::rare_power_max())
        } else if (rarity == constants::rarity_epic()) {
            random::generate_u8_in_range(gen, constants::epic_power_min(), constants::epic_power_max())
        } else {
            random::generate_u8_in_range(gen, constants::legendary_power_min(), constants::legendary_power_max())
        }
    }

    // ── Test helper (stripped from production builds) ─────────
    // FIX 2: The test helper was accidentally appended OUTSIDE the closing brace.
    // Moved inside the module here.
    #[test_only]
    public fun test_determine_rarity(config: &GameConfig, roll: u8): u8 {
        determine_rarity(config, roll)
    }
}
