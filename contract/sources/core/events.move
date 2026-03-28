/// events.move
/// ─────────────────────────────────────────────────────────────
/// All on-chain events emitted by the VaultX package.
///
/// WHAT ARE SUI EVENTS?
/// Events are side-effects of transactions that get permanently
/// recorded on-chain and broadcast to subscribers.  They do NOT
/// change object state — they are write-once log entries.
///
/// WHO READS THEM?
///   - Frontend: listens via suiClient.subscribeEvent() or polls
///     suiClient.queryEvents() to update the UI in real time
///   - Indexers: build queryable databases of game history
///   - Players: can look up raw events to verify fairness
///     (e.g. "was my raw_roll really 97? let me check on-chain")
///
/// RULE: Emit BEFORE the final transfer() call in each function.
/// This ensures the event data is captured even if a later step
/// theoretically failed (atomic in practice, but good convention).
///
/// ALL EVENTS are emitted via: sui::event::emit(EventStruct { ... })
module vaultx::events {

    use std::string::String;

    // ── LootBoxPurchased ──────────────────────────────────────
    /// Emitted when a player successfully buys a loot box.
    /// Frontend: confirm purchase, show new box in inventory.
    public struct LootBoxPurchased has copy, drop {
        /// Object ID of the newly minted LootBox NFT
        box_id: ID,

        /// Wallet address of the buyer
        buyer: address,

        /// Sequential number: total_boxes_sold at time of purchase.
        /// Lets you say "you bought box #47 out of all boxes ever sold".
        box_number: u64,

        /// Amount paid in MIST (should equal token_price)
        amount_paid: u64,

        /// Blockchain clock timestamp in milliseconds
        timestamp_ms: u64,
    }

    // ── LootBoxOpened ─────────────────────────────────────────
    /// Emitted when a player opens a loot box and receives an item.
    /// This single event carries everything the UI needs for the
    /// full reveal animation sequence.
    public struct LootBoxOpened has copy, drop {
        /// Object ID of the LootBox that was burned
        box_id: ID,

        /// Object ID of the newly minted GameItem
        item_id: ID,

        /// Rarity tier: 0=Common 1=Rare 2=Epic 3=Legendary
        rarity: u8,

        /// Power level (1-50 depending on tier)
        power: u8,

        /// Player's wallet address (receives the item)
        owner: address,

        /// The actual 0-99 number that was rolled on-chain.
        /// Published for transparency — anyone can verify:
        ///   roll 0-59 → Common, 60-84 → Rare, 85-96 → Epic, 97-99 → Legendary
        raw_roll: u8,

        /// Whether pity system activated this Legendary
        /// (false for normal Legendary drops, true for pity triggers)
        pity_triggered: bool,

        /// Blockchain clock timestamp in milliseconds
        timestamp_ms: u64,
    }

    // ── ItemTransferred ───────────────────────────────────────
    /// Emitted when a player sends their GameItem to another wallet.
    /// Frontend: remove item from sender's inventory, add to recipient's.
    public struct ItemTransferred has copy, drop {
        /// Object ID of the item that was transferred
        item_id: ID,

        /// Item name (e.g. "Legendary Item #42") for display
        item_name: String,

        /// Rarity for indexer filtering
        rarity: u8,

        /// Sender's wallet address
        from: address,

        /// Recipient's wallet address
        to: address,

        /// Blockchain clock timestamp in milliseconds
        timestamp_ms: u64,
    }

    // ── ItemBurned ────────────────────────────────────────────
    /// Emitted when a player permanently destroys a GameItem.
    /// Frontend: remove from inventory.
    /// Future crafting systems: listen for this as proof-of-burn.
    public struct ItemBurned has copy, drop {
        /// Object ID of the destroyed item (captured before deletion)
        item_id: ID,

        /// Item name for display
        item_name: String,

        /// Rarity for supply-tracking (supply per tier decreases)
        rarity: u8,

        /// Owner who burned it
        owner: address,

        /// Blockchain clock timestamp in milliseconds
        timestamp_ms: u64,
    }

    // ── RarityWeightsUpdated ──────────────────────────────────
    /// Emitted when admin changes the drop rate weights.
    /// Makes every admin action auditable on-chain — players can
    /// look up the full history of weight changes and verify what
    /// the rates were at the exact moment they opened their box.
    public struct RarityWeightsUpdated has copy, drop {
        new_common:    u8,
        new_rare:      u8,
        new_epic:      u8,
        new_legendary: u8,

        /// Admin wallet address (for audit trail)
        updated_by: address,

        timestamp_ms: u64,
    }

    // ── PriceUpdated ──────────────────────────────────────────
    /// Emitted when admin changes the box price.
    public struct PriceUpdated has copy, drop {
        old_price: u64,
        new_price: u64,
        updated_by: address,
        timestamp_ms: u64,
    }

    // ── GamePauseToggled ──────────────────────────────────────
    /// Emitted when admin pauses or unpauses the game.
    public struct GamePauseToggled has copy, drop {
        is_paused:  bool,
        toggled_by: address,
        timestamp_ms: u64,
    }

    // ── TreasuryWithdrawn ─────────────────────────────────────
    /// Emitted when admin withdraws accumulated SUI from the treasury.
    public struct TreasuryWithdrawn has copy, drop {
        amount_mist: u64,
        recipient:   address,
        timestamp_ms: u64,
    }

    // ── Emit helpers ──────────────────────────────────────────
    // Each function is a thin wrapper around sui::event::emit().
    // Callers import and call e.g. events::emit_box_purchased(...).
    // This keeps the emit calls readable and typed.

    public fun emit_box_purchased(
        box_id: ID, buyer: address, box_number: u64,
        amount_paid: u64, timestamp_ms: u64,
    ) {
        sui::event::emit(LootBoxPurchased { box_id, buyer, box_number, amount_paid, timestamp_ms });
    }

    public fun emit_box_opened(
        box_id: ID, item_id: ID, rarity: u8, power: u8,
        owner: address, raw_roll: u8, pity_triggered: bool, timestamp_ms: u64,
    ) {
        sui::event::emit(LootBoxOpened {
            box_id, item_id, rarity, power, owner, raw_roll, pity_triggered, timestamp_ms
        });
    }

    public fun emit_item_transferred(
        item_id: ID, item_name: String, rarity: u8,
        from: address, to: address, timestamp_ms: u64,
    ) {
        sui::event::emit(ItemTransferred { item_id, item_name, rarity, from, to, timestamp_ms });
    }

    public fun emit_item_burned(
        item_id: ID, item_name: String, rarity: u8,
        owner: address, timestamp_ms: u64,
    ) {
        sui::event::emit(ItemBurned { item_id, item_name, rarity, owner, timestamp_ms });
    }

    public fun emit_weights_updated(
        new_common: u8, new_rare: u8, new_epic: u8, new_legendary: u8,
        updated_by: address, timestamp_ms: u64,
    ) {
        sui::event::emit(RarityWeightsUpdated {
            new_common, new_rare, new_epic, new_legendary, updated_by, timestamp_ms
        });
    }

    public fun emit_price_updated(
        old_price: u64, new_price: u64, updated_by: address, timestamp_ms: u64,
    ) {
        sui::event::emit(PriceUpdated { old_price, new_price, updated_by, timestamp_ms });
    }

    public fun emit_pause_toggled(
        is_paused: bool, toggled_by: address, timestamp_ms: u64,
    ) {
        sui::event::emit(GamePauseToggled { is_paused, toggled_by, timestamp_ms });
    }

    public fun emit_treasury_withdrawn(
        amount_mist: u64, recipient: address, timestamp_ms: u64,
    ) {
        sui::event::emit(TreasuryWithdrawn { amount_mist, recipient, timestamp_ms });
    }
}
