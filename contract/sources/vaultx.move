/// vaultx.move
/// ─────────────────────────────────────────────────────────────
/// Package entry point.  The ONLY module with an init() function.
///
/// WHY ONE INIT?
/// Sui calls init() once, automatically, when the package is
/// published.  If multiple modules had init(), the framework would
/// call all of them, which can cause ordering issues.  We centralise
/// deployment here and delegate to the relevant modules.
///
/// WHAT init() DOES:
///   1. Creates AdminCap → transfers to deployer wallet
///   2. Creates GameConfig with defaults → shares it globally
///
/// After deployment:
///   - Deployer's wallet holds AdminCap (they are admin)
///   - GameConfig exists on-chain as a shared object
///   - The package is live and players can immediately buy boxes
///
/// MODULE STRUCTURE OVERVIEW:
/// ┌─ sources/
/// │  ├─ core/
/// │  │  ├─ constants.move   — all magic numbers in one place
/// │  │  ├─ errors.move      — all abort codes in one place
/// │  │  ├─ config.move      — GameConfig shared object
/// │  │  └─ events.move      — all on-chain event structs + emitters
/// │  ├─ game/
/// │  │  ├─ loot_box.move    — LootBox object + buy flow
/// │  │  ├─ game_item.move   — GameItem NFT + transfer + burn
/// │  │  ├─ pity.move        — pity system (dynamic fields)
/// │  │  └─ open_box.move    — secure entry function (randomness)
/// │  ├─ admin/
/// │  │  └─ admin.move       — AdminCap + admin operations
/// │  └─ vaultx.move         ← YOU ARE HERE (init only)
/// └─ tests/
///    ├─ test_buy.move
///    ├─ test_open.move
///    ├─ test_transfer_burn.move
///    ├─ test_admin.move
///    └─ test_pity.move
module vaultx::vaultx {

    use vaultx::admin;
    use vaultx::config;

    /// Called automatically by the Sui framework when the package
    /// is published.  Runs exactly once — cannot be called again.
    ///
    /// Creates:
    ///   1. AdminCap → transferred to deployer (tx_context::sender)
    ///   2. GameConfig → shared globally (accessible by all players)
    fun init(ctx: &mut TxContext) {
        // AdminCap goes to whoever published the contract
        admin::create_and_transfer(ctx);

        // GameConfig is shared — lives on-chain forever
        config::create_and_share(ctx);
    }
}
