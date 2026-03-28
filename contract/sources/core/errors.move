/// errors.move
/// ─────────────────────────────────────────────────────────────
/// Central registry of every abort code in the VaultX package.
///
/// WHY CENTRALISE ERROR CODES?
/// - One place to look up what any abort means
/// - Prevents duplicate values across modules
/// - Frontend / indexers can map raw codes to human messages
///
/// NAMING CONVENTION:
/// Constants are E_SCREAMING_SNAKE so they're visually distinct
/// from regular variables at the call site:
///   assert!(ok, errors::E_GAME_PAUSED);
///
/// VALUES start at 1000 so they can't be confused with
/// Sui framework's own internal error codes (which are low integers).
module vaultx::errors {

    // ── Game state errors ─────────────────────────────────────

    /// Game is currently paused by admin.
    /// Both purchase_loot_box and open_loot_box check this.
    const E_GAME_PAUSED: u64 = 1001;

    // ── Payment errors ────────────────────────────────────────

    /// Coin value sent does not equal token_price exactly.
    /// VaultX requires exact payment; the frontend must split
    /// the coin to the right amount before calling buy_box.
    const E_WRONG_PAYMENT: u64 = 1002;

    // ── Admin / weight errors ─────────────────────────────────

    /// The four rarity weights don't sum to exactly 100.
    /// The random roll is 0-99, so weights must cover all 100 values.
    const E_WEIGHTS_NOT_100: u64 = 1003;

    /// A weight value is 0 — disabling a tier entirely is not allowed.
    /// Every rarity must always be achievable.
    const E_WEIGHT_TOO_LOW: u64 = 1004;

    // ── Transfer / burn errors ────────────────────────────────

    /// Recipient address is the zero address (0x0).
    /// Use burn_item to destroy; transfer to 0x0 is not valid.
    const E_INVALID_RECIPIENT: u64 = 1005;

    // ── Randomness security errors ────────────────────────────

    /// The Random object passed to open_box is not at address 0x8.
    /// This guards against a fake Random object being passed in.
    const E_INVALID_RANDOM_OBJECT: u64 = 1006;

    // ── Public accessor functions ─────────────────────────────
    // Move doesn't export constants across modules, so we expose
    // each one through a public fun. Callers do:
    //   assert!(condition, errors::e_game_paused());

    public fun e_game_paused(): u64          { E_GAME_PAUSED }
    public fun e_wrong_payment(): u64        { E_WRONG_PAYMENT }
    public fun e_weights_not_100(): u64      { E_WEIGHTS_NOT_100 }
    public fun e_weight_too_low(): u64       { E_WEIGHT_TOO_LOW }
    public fun e_invalid_recipient(): u64    { E_INVALID_RECIPIENT }
    public fun e_invalid_random_object(): u64 { E_INVALID_RANDOM_OBJECT }
}
