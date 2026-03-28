/// config.move
/// ─────────────────────────────────────────────────────────────
/// Defines the GameConfig shared object — the single on-chain
/// "settings file" for the entire VaultX game.
///
/// WHAT IS A SHARED OBJECT?
/// On Sui, every object is either:
///   - Owned: lives in exactly one wallet, only that wallet can use it
///   - Shared: lives on-chain globally, any wallet can interact with it
///
/// GameConfig is shared because every player's buy_box and open_box
/// transaction needs to read/write it (treasury, counter, weights).
/// It is created once in init() and shared forever — this is irreversible.
///
/// FIELD VISIBILITY:
/// Fields are private (Move default). Reads go through public fun
/// getters; writes go through package-visible setters that only
/// sibling modules (game, admin) can call.  This enforces that no
/// external contract can mutate our config directly.
module vaultx::config {

    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use vaultx::constants;

    // ── The main config object ────────────────────────────────
    public struct GameConfig has key {
        id: UID,

        /// Price in MIST a player must pay per loot box.
        /// Set at deploy time; admin can update via update_price().
        token_price: u64,

        /// Drop-rate weights.  Must always sum to exactly 100.
        /// The random roll (0-99) maps directly:
        ///   0  .. common_weight-1              → Common
        ///   ..  .. +rare_weight-1              → Rare
        ///   ..  .. +epic_weight-1              → Epic
        ///   rest                               → Legendary
        common_weight:    u8,
        rare_weight:      u8,
        epic_weight:      u8,
        legendary_weight: u8,

        /// Running counter of every box ever sold.
        /// Used as the sequential box_number on each LootBox.
        total_boxes_sold: u64,

        /// Accumulated SUI payments from all box purchases.
        /// Admin withdraws this via withdraw_treasury().
        treasury: Balance<SUI>,

        /// Emergency stop flag.  When true, buy_box and open_box abort.
        /// Admin flips via set_paused().
        is_paused: bool,
    }

    // ── Constructor (called once from game::init) ─────────────
    /// Creates the GameConfig with default values and shares it
    /// globally.  After share_object() this cannot be un-shared.
    public(package) fun create_and_share(ctx: &mut TxContext) {
        let config = GameConfig {
            id:               object::new(ctx),
            token_price:      constants::default_price_mist(),
            common_weight:    constants::default_common_weight(),
            rare_weight:      constants::default_rare_weight(),
            epic_weight:      constants::default_epic_weight(),
            legendary_weight: constants::default_legendary_weight(),
            total_boxes_sold: 0,
            treasury:         balance::zero<SUI>(),
            is_paused:        false,
        };
        transfer::share_object(config);
    }

    // ── Package-visible setters ───────────────────────────────
    // Only modules in the same package (game.move, admin.move) can
    // call these.  External contracts cannot mutate config directly.

    /// Update all four rarity weights atomically.
    /// Caller MUST validate they sum to 100 before calling.
    public(package) fun set_weights(
        config: &mut GameConfig,
        common: u8,
        rare:   u8,
        epic:   u8,
        legendary: u8,
    ) {
        config.common_weight    = common;
        config.rare_weight      = rare;
        config.epic_weight      = epic;
        config.legendary_weight = legendary;
    }

    /// Update the box price.
    public(package) fun set_price(config: &mut GameConfig, price: u64) {
        config.token_price = price;
    }

    /// Flip the pause flag.
    public(package) fun set_paused(config: &mut GameConfig, paused: bool) {
        config.is_paused = paused;
    }

    /// Increment total_boxes_sold by 1.
    /// Called during every successful buy_box.
    public(package) fun increment_boxes_sold(config: &mut GameConfig) {
        config.total_boxes_sold = config.total_boxes_sold + 1;
    }

    /// Merge a payment Balance into the treasury.
    /// The Balance is consumed (moved) — no copy possible.
    public(package) fun deposit_to_treasury(
        config: &mut GameConfig,
        payment: Balance<SUI>,
    ) {
        balance::join(&mut config.treasury, payment);
    }

    /// Withdraw the entire treasury to a Coin and return it.
    /// Only admin.move calls this (it requires AdminCap).
    public(package) fun withdraw_treasury(
        config: &mut GameConfig,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        let amount = balance::value(&config.treasury);
        // split() takes exactly `amount` from the balance — empties it
        let withdrawn = balance::split(&mut config.treasury, amount);
        coin::from_balance(withdrawn, ctx)
    }

    // ── Public read accessors ─────────────────────────────────
    // These are truly public — any module or script can call them.

    public fun price(config: &GameConfig): u64           { config.token_price }
    public fun common_weight(config: &GameConfig): u8    { config.common_weight }
    public fun rare_weight(config: &GameConfig): u8      { config.rare_weight }
    public fun epic_weight(config: &GameConfig): u8      { config.epic_weight }
    public fun legendary_weight(config: &GameConfig): u8 { config.legendary_weight }
    public fun total_boxes_sold(config: &GameConfig): u64 { config.total_boxes_sold }
    public fun is_paused(config: &GameConfig): bool      { config.is_paused }
    public fun treasury_balance(config: &GameConfig): u64 { balance::value(&config.treasury) }

    /// Immutable reference to the object ID.
    /// Needed by game.move to key dynamic fields (pity tracker).
    public fun uid(config: &GameConfig): &UID { &config.id }

    /// Mutable reference to the object ID.
    /// Needed to add/update/read dynamic fields on the config.
    public fun uid_mut(config: &mut GameConfig): &mut UID { &mut config.id }
}
