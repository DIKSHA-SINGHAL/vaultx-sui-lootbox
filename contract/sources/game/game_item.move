/// game_item.move
/// ─────────────────────────────────────────────────────────────
/// Defines the GameItem NFT and all lifecycle operations:
/// minting (internal), transfer, burn, and read accessors.
///
/// WHAT IS A GAMEITEM?
/// The actual reward.  Minted the moment a player opens their LootBox.
/// Has 'key + store' abilities:
///   - key:   it's a proper Sui object with a unique on-chain ID
///   - store: it can be transferred and is composable — future
///            systems like marketplaces or crafting can hold it
///
/// Two items with the same rarity and power are still different
/// objects — different UIDs, different origin_boxes, different
/// minted_at timestamps.
///
/// LIFECYCLE:
///   does not exist
///     → minted by game::open_box()
///     → lives in player's wallet (can be transferred N times)
///     → optionally burned via burn() → permanently deleted
module vaultx::game_item {

    use std::string::{Self, String};
    use sui::clock::{Self, Clock};
    use vaultx::constants;
    use vaultx::errors;
    use vaultx::events;

    // ── Object definition ─────────────────────────────────────

    /// A minted NFT game item.  Each one is unique (different UID).
    /// has key + store → transferable, composable with future systems.
    public struct GameItem has key, store {
        id: UID,

        /// Human-readable name generated at mint time.
        /// Format: "{Rarity} Item #{box_number}"
        /// e.g. "Legendary Item #42"
        name: String,

        /// Rarity tier: 0=Common 1=Rare 2=Epic 3=Legendary
        /// Frontend maps to colour: grey / blue / purple / gold
        rarity: u8,

        /// Strength of the item within the tier's range:
        ///   Common 1-10, Rare 11-25, Epic 26-40, Legendary 41-50
        power: u8,

        /// Clock timestamp (ms) when this item was minted.
        minted_at: u64,

        /// The box_number of the LootBox that produced this item.
        /// Provenance trail: you can always trace which purchase led here.
        origin_box: u64,

        /// Current owner's wallet address.
        /// Updated on each transfer so the item always knows its owner.
        owner: address,
    }

    // ── Constructor (package-visible) ─────────────────────────
    /// Mints a new GameItem.  Only game::open_box can call this.
    /// External contracts cannot mint items directly — this is a
    /// core security property of the system.
    public(package) fun mint(
        rarity:     u8,
        power:      u8,
        origin_box: u64,
        owner:      address,
        clock:      &Clock,
        ctx:        &mut TxContext,
    ): GameItem {
        let name = build_name(rarity, origin_box);
        GameItem {
            id:         object::new(ctx),
            name,
            rarity,
            power,
            minted_at:  clock::timestamp_ms(clock),
            origin_box,
            owner,
        }
    }

    // ── Transfer ──────────────────────────────────────────────

    /// Transfer a GameItem to another wallet address.
    ///
    /// SECURITY NOTE:
    /// Sui's VM already enforces that only the owner can call entry
    /// functions that consume their objects.  If you pass a GameItem
    /// you don't own, the VM rejects it before this function runs.
    /// No explicit ownership check needed.
    ///
    /// PARAMETERS:
    ///   item      — the owned GameItem to transfer (consumed)
    ///   recipient — target wallet address
    ///   clock     — for timestamp in emitted event
    ///   ctx       — for sender address in event
    public fun transfer_item(
        mut item:  GameItem,
        recipient: address,
        clock:     &Clock,
        ctx:       &TxContext,
    ) {
        // Guard: don't allow transfer to the zero address.
        // If the player wants to destroy, they should use burn_item().
        assert!(
            recipient != @0x0,
            errors::e_invalid_recipient()
        );

        let item_id   = object::id(&item);
        let item_name = item.name;
        let rarity    = item.rarity;
        let from      = tx_context::sender(ctx);

        // Update the owner field to reflect new ownership
        item.owner = recipient;

        // Emit BEFORE transfer (convention)
        events::emit_item_transferred(
            item_id, item_name, rarity, from, recipient,
            clock::timestamp_ms(clock),
        );

        transfer::public_transfer(item, recipient);
    }

    // ── Burn ──────────────────────────────────────────────────

    /// Permanently destroy a GameItem.
    /// Irreversible — the object is deleted from chain state.
    ///
    /// Use cases:
    ///   - Player clearing inventory
    ///   - Future crafting system: burn items as input to create new ones
    ///
    /// Future crafting systems should listen for the ItemBurned event
    /// as on-chain proof that items were burned as crafting input.
    public fun burn_item(
        item:  GameItem,
        clock: &Clock,
        ctx:   &TxContext,
    ) {
        // Capture fields BEFORE destructuring (needed for event)
        let item_id   = object::id(&item);
        let item_name = item.name;
        let rarity    = item.rarity;
        let owner     = tx_context::sender(ctx);

        // Emit BEFORE deletion (after this point item no longer exists)
        events::emit_item_burned(
            item_id, item_name, rarity, owner,
            clock::timestamp_ms(clock),
        );

        // Destructure and delete the object from chain state
        let GameItem { id, name: _, rarity: _, power: _, minted_at: _, origin_box: _, owner: _ } = item;
        object::delete(id);
    }

    // ── Read accessors ────────────────────────────────────────
    // These satisfy the PRD's get_item_stats() requirement.
    // They are read-only (immutable reference) — zero gas cost beyond RPC.

    public fun name(item: &GameItem): String  { item.name }
    public fun rarity(item: &GameItem): u8    { item.rarity }
    public fun power(item: &GameItem): u8     { item.power }
    public fun minted_at(item: &GameItem): u64 { item.minted_at }
    public fun origin_box(item: &GameItem): u64 { item.origin_box }
    public fun owner(item: &GameItem): address { item.owner }

    // ── Internal helpers ──────────────────────────────────────

    /// Build the human-readable item name from rarity + box number.
    /// e.g. rarity=3, box_number=42 → "Legendary Item #42"
    fun build_name(rarity: u8, box_number: u64): String {
        let prefix = if (rarity == constants::rarity_common())    { b"Common" }
               else if (rarity == constants::rarity_rare())      { b"Rare" }
               else if (rarity == constants::rarity_epic())      { b"Epic" }
               else                                               { b"Legendary" };

        let mut name = string::utf8(prefix);
        string::append(&mut name, string::utf8(b" Item #"));
        string::append(&mut name, u64_to_string(box_number));
        name
    }

    /// Converts a u64 to its decimal String representation.
    /// e.g. 42 → "42",  0 → "0"
    fun u64_to_string(mut n: u64): String {
        if (n == 0) { return string::utf8(b"0") };

        let mut digits = vector::empty<u8>();
        while (n > 0) {
            // Extract least-significant digit, convert to ASCII ('0' = 48)
            vector::push_back(&mut digits, ((n % 10) as u8) + 48);
            n = n / 10;
        };
        // Digits were pushed least-significant first → reverse
        vector::reverse(&mut digits);
        string::utf8(digits)
    }
}
