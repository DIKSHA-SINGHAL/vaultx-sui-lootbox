/// loot_box.move
/// ─────────────────────────────────────────────────────────────
/// Defines the LootBox object and the purchase flow.
///
/// WHAT IS A LOOTBOX OBJECT?
/// A LootBox is a receipt NFT.  When a player pays, a LootBox is
/// minted and sent to their wallet.  It represents "paid but not
/// opened yet".  No item is inside it — the actual item is decided
/// at the moment of opening, not purchase.
///
/// KEY DESIGN DECISION — has key only (no store):
/// LootBox cannot be transferred to another wallet.  This is
/// intentional: if boxes were transferable, a secondary market for
/// unopened boxes would form, creating gambling-arbitrage problems.
/// It is bound to the wallet that bought it.
///
/// LIFECYCLE:
///   does not exist
///     → minted by buy_box() → lives in player's wallet
///     → consumed by open_box() in game.move → permanently deleted
///
/// BUY FLOW STEPS (from PRD section 4.2):
///   1. Assert !is_paused
///   2. Assert payment == token_price exactly
///   3. Merge payment into treasury
///   4. Increment total_boxes_sold
///   5. Mint LootBox with box_number = new total
///   6. Emit LootBoxPurchased event
///   7. Transfer LootBox to player
module vaultx::loot_box {

    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use vaultx::config::{Self, GameConfig};
    use vaultx::errors;
    use vaultx::events;

    // ── Object definition ─────────────────────────────────────

    /// An unopened loot box.  Minted on purchase, destroyed on open.
    /// has key only → NOT transferable after creation.
    public struct LootBox has key {
        id: UID,

        /// Wallet address that purchased this box.
        /// Captured from tx_context::sender() at purchase time.
        owner: address,

        /// Clock timestamp (ms) when this box was purchased.
        /// Displayed in the "Purchased 3/25/2026" label on the UI.
        purchased_at: u64,

        /// Sequential number of this box.  Box #1, #2, #3…
        /// Copied from total_boxes_sold at purchase time.
        /// Stored on the resulting GameItem as origin_box so you can
        /// always trace which purchase produced which item.
        box_number: u64,
    }

    // ── Public accessors ──────────────────────────────────────
    // game.move needs to read these when destroying the box in open_box()

    public fun box_number(loot_box: &LootBox): u64      { loot_box.box_number }
    public fun owner(loot_box: &LootBox): address        { loot_box.owner }
    public fun purchased_at(loot_box: &LootBox): u64    { loot_box.purchased_at }

    // ── Destructor (package-visible) ──────────────────────────
    /// Unpacks and deletes a LootBox.  Returns fields needed by open_box().
    /// Called only by game::open_box — no external module can burn a box.
    public(package) fun destroy(loot_box: LootBox): (u64, address) {
        let LootBox { id, box_number, owner, purchased_at: _ } = loot_box;
        object::delete(id);
        (box_number, owner)
    }

    // ── Purchase entry point ──────────────────────────────────

    /// Buy a loot box.  Deducts exactly token_price from the payment
    /// coin, mints a LootBox NFT, and transfers it to the caller.
    ///
    /// PARAMETERS:
    ///   config  — shared GameConfig (mutable: treasury + counter written)
    ///   payment — a Coin<SUI> of exactly token_price MIST
    ///             (frontend must call tx.splitCoins before this)
    ///   clock   — Sui's global clock object at 0x6
    ///   ctx     — transaction context (gives us sender address + new IDs)
    public fun buy(
        config:  &mut GameConfig,
        payment: Coin<SUI>,
        clock:   &Clock,
        ctx:     &mut TxContext,
    ) {
        // ── Guard: game must not be paused ────────────────────
        assert!(!config::is_paused(config), errors::e_game_paused());

        // ── Guard: exact payment ──────────────────────────────
        // We require exact payment (not >= price) for simplicity.
        // The frontend computes the exact split before submitting.
        assert!(
            coin::value(&payment) == config::price(config),
            errors::e_wrong_payment()
        );

        // ── Record payment ────────────────────────────────────
        // coin::into_balance() consumes the Coin and returns its Balance.
        // deposit_to_treasury() joins it into config.treasury.
        config::deposit_to_treasury(config, coin::into_balance(payment));

        // ── Increment counter ─────────────────────────────────
        config::increment_boxes_sold(config);

        let box_number = config::total_boxes_sold(config);
        let buyer      = tx_context::sender(ctx);
        let now_ms     = clock::timestamp_ms(clock);

        // ── Mint the LootBox ──────────────────────────────────
        let loot_box = LootBox {
            id:           object::new(ctx),
            owner:        buyer,
            purchased_at: now_ms,
            box_number,
        };

        // ── Emit event BEFORE transfer (convention) ───────────
        events::emit_box_purchased(
            object::id(&loot_box),
            buyer,
            box_number,
            config::price(config),
            now_ms,
        );

        // ── Transfer box to player ────────────────────────────
        transfer::transfer(loot_box, buyer);
    }
}
