/// admin.move
/// ─────────────────────────────────────────────────────────────
/// Admin capability and all admin-only operations:
///   - update_weights  (adjust drop rates)
///   - update_price    (change box cost)
///   - set_paused      (emergency stop)
///   - withdraw        (claim treasury SUI)
///
/// HOW SUI CAPABILITY OBJECTS WORK:
/// Instead of "check if sender == hardcoded admin address", we use
/// a capability pattern:
///   - AdminCap is an object with 'key' ability only
///   - It is created once at deploy time and sent to the deployer
///   - Any function that requires admin passes &AdminCap as a param
///   - If you don't hold AdminCap in your wallet, the VM rejects the tx
///     before the function even starts
///
/// This means:
///   - Transferring admin = transferring the AdminCap object
///   - No contract upgrade needed to change admins
///   - The access control is enforced by the object model, not code
///
/// ⚠ CRITICAL WARNING — AdminCap has 'key' only, NOT 'store':
/// This means it CANNOT be transferred after creation.
/// If the admin wallet's private key is lost, admin functions are
/// permanently locked.  Use a multi-sig wallet for production.
module vaultx::admin {

    use sui::clock::{Self, Clock};
    use vaultx::config::{Self, GameConfig};
    use vaultx::errors;
    use vaultx::events;

    // ── Capability object ─────────────────────────────────────

    /// The admin capability.  Holding this in your wallet = you are admin.
    /// has key only (no store) → cannot be transferred after creation.
    public struct AdminCap has key {
        id: UID,
    }

    // ── Constructor (package-visible, called from game::init) ─────

    /// Creates the AdminCap and transfers it to the contract deployer.
    /// Called exactly once during module initialisation.
    public(package) fun create_and_transfer(ctx: &mut TxContext) {
        let cap = AdminCap { id: object::new(ctx) };
        transfer::transfer(cap, tx_context::sender(ctx));
    }

    // ── Admin functions ───────────────────────────────────────

    /// Update rarity drop rate weights.
    ///
    /// REQUIREMENTS:
    ///   - weights must sum to exactly 100
    ///   - no weight can be 0 (would permanently disable a tier)
    ///
    /// Changes take effect immediately on the NEXT open_box call.
    /// Emits RarityWeightsUpdated for on-chain audit trail.
    public fun update_weights(
        _cap:      &AdminCap,     // proves caller holds AdminCap
        config:    &mut GameConfig,
        common:    u8,
        rare:      u8,
        epic:      u8,
        legendary: u8,
        clock:     &Clock,
        ctx:       &TxContext,
    ) {
        // Weights must sum to exactly 100
        assert!(
            (common as u64) + (rare as u64) + (epic as u64) + (legendary as u64) == 100,
            errors::e_weights_not_100()
        );

        // No tier can be disabled entirely
        assert!(common >= 1 && rare >= 1 && epic >= 1 && legendary >= 1, errors::e_weight_too_low());

        config::set_weights(config, common, rare, epic, legendary);

        events::emit_weights_updated(
            common, rare, epic, legendary,
            tx_context::sender(ctx),
            clock::timestamp_ms(clock),
        );
    }

    /// Update the price of a loot box.
    /// New price takes effect on the next buy_box call.
    public fun update_price(
        _cap:      &AdminCap,
        config:    &mut GameConfig,
        new_price: u64,
        clock:     &Clock,
        ctx:       &TxContext,
    ) {
        let old_price = config::price(config);
        config::set_price(config, new_price);

        events::emit_price_updated(
            old_price,
            new_price,
            tx_context::sender(ctx),
            clock::timestamp_ms(clock),
        );
    }

    /// Pause or unpause the game.
    ///
    /// When paused: buy_box and open_box abort with E_GAME_PAUSED.
    /// Use in emergencies (bug found, hack detected, maintenance).
    public fun set_paused(
        _cap:   &AdminCap,
        config: &mut GameConfig,
        paused: bool,
        clock:  &Clock,
        ctx:    &TxContext,
    ) {
        config::set_paused(config, paused);

        events::emit_pause_toggled(
            paused,
            tx_context::sender(ctx),
            clock::timestamp_ms(clock),
        );
    }

    /// Withdraw all accumulated SUI from the treasury.
    ///
    /// All player payments (box purchases) accumulate in the treasury.
    /// This is the only way to extract revenue from the contract.
    /// Without this function, the SUI would be locked in the contract forever.
    ///
    /// The entire balance is withdrawn to the caller (admin) wallet.
    /// If you want partial withdrawals, split the output coin yourself.
    public fun withdraw_treasury(
        _cap:   &AdminCap,
        config: &mut GameConfig,
        clock:  &Clock,
        ctx:    &mut TxContext,
    ) {
        let amount = config::treasury_balance(config);
        let coin   = config::withdraw_treasury(config, ctx);

        let recipient = tx_context::sender(ctx);

        events::emit_treasury_withdrawn(
            amount,
            recipient,
            clock::timestamp_ms(clock),
        );

        transfer::public_transfer(coin, recipient);
    }
}

