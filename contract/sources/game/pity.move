/// pity.move
/// ─────────────────────────────────────────────────────────────
/// Pity system: after 30 consecutive non-Legendary opens, the
/// player's next open is guaranteed Legendary.
///
/// WHAT ARE DYNAMIC FIELDS?
/// On Sui, you can attach arbitrary key-value data to any object
/// at runtime using sui::dynamic_field.  We attach a
/// UserPityTracker to GameConfig, keyed by the player's address.
///
/// WHY DYNAMIC FIELDS INSTEAD OF A SEPARATE TABLE?
/// - No pre-allocation needed (only players who have opened a box
///   have an entry — players who never opened have no record)
/// - The data is stored ON the GameConfig object, not separately
/// - Removes the need for a global mapping object
/// - Sui-idiomatic for per-user state attached to shared config
///
/// TRACKER LIFECYCLE:
///   player opens box → tracker doesn't exist yet → create with boxes_opened=1
///   player opens box → tracker exists, non-Legendary → increment
///   player opens box → boxes_opened reaches PITY_THRESHOLD → pity_active=true
///   player opens box → pity_active=true → Legendary forced, then RESET
///   player gets Legendary (luck or pity) → reset to boxes_opened=0, pity_active=false
module vaultx::pity {

    use sui::dynamic_field;
    use vaultx::config::{Self, GameConfig};
    use vaultx::constants;

    // ── Tracker struct ────────────────────────────────────────

    /// Per-player pity state.  Stored as a dynamic field on GameConfig.
    /// The key is the player's address.
    ///
    /// has store: required to be a dynamic field value
    /// has drop:  allows the struct to be silently dropped when
    ///            the parent object is deleted (safety requirement)
    public struct UserPityTracker has store, drop {
        /// How many boxes this player has opened since their last
        /// Legendary drop.  Resets to 0 on any Legendary drop.
        boxes_opened: u32,

        /// Flips to true when boxes_opened reaches PITY_THRESHOLD.
        /// When true, the NEXT open is guaranteed Legendary.
        pity_active: bool,
    }

    // ── Public interface ──────────────────────────────────────

    /// Check whether this player currently has pity active.
    /// Called at the START of open_box, before rolling randomness.
    /// If true, rarity is forced to Legendary regardless of roll.
    public(package) fun is_pity_active(
        config: &GameConfig,
        player: address,
    ): bool {
        if (!dynamic_field::exists_(config::uid(config), player)) {
            // No record yet → first time opening, no pity possible
            return false
        };
        let tracker: &UserPityTracker =
            dynamic_field::borrow(config::uid(config), player);
        tracker.pity_active
    }

    /// Update the pity tracker after a box is opened.
    /// Called at the END of open_box, after rarity is determined.
    ///
    /// Rules:
    ///   - If Legendary dropped (luck or pity): reset counter to 0
    ///   - If non-Legendary: increment counter
    ///   - If counter reaches threshold: set pity_active = true
    public(package) fun record_open(
        config: &mut GameConfig,
        player: address,
        rarity: u8,
    ) {
        let got_legendary = (rarity == constants::rarity_legendary());

        if (dynamic_field::exists_(config::uid(config), player)) {
            // Tracker already exists — update it
            let tracker: &mut UserPityTracker =
                dynamic_field::borrow_mut(config::uid_mut(config), player);

            if (got_legendary) {
                // Reset: Legendary resets pity regardless of how it was triggered
                tracker.boxes_opened = 0;
                tracker.pity_active  = false;
            } else {
                // Non-Legendary: increment the "dry streak" counter
                tracker.boxes_opened = tracker.boxes_opened + 1;
                // If we've hit the threshold, arm pity for the next open
                if (tracker.boxes_opened >= constants::pity_threshold()) {
                    tracker.pity_active = true;
                }
            }
        } else {
            // No tracker yet (first time this player opens a box) → create one
            let boxes_opened = if (got_legendary) { 0 } else { 1 };
            let pity_active  = boxes_opened >= constants::pity_threshold();

            dynamic_field::add(
                config::uid_mut(config),
                player,
                UserPityTracker { boxes_opened, pity_active },
            );
        }
    }

    /// Read-only: how many consecutive non-Legendary opens this player has.
    /// Used by tests and potentially by a future "pity progress" UI endpoint.
    public(package) fun boxes_opened_count(
        config: &GameConfig,
        player: address,
    ): u32 {
        if (!dynamic_field::exists_(config::uid(config), player)) {
            return 0
        };
        let tracker: &UserPityTracker =
            dynamic_field::borrow(config::uid(config), player);
        tracker.boxes_opened
    }
}
