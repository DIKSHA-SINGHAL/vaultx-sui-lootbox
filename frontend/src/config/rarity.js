/**
 * config/rarity.js
 * ─────────────────────────────────────────────────────────────
 * Single source of truth for rarity data.
 *
 * The Move contract stores rarity as a raw u8:
 *   0 = Common  |  1 = Rare  |  2 = Epic  |  3 = Legendary
 *
 * FIELD NOTE:
 *   pct       — drop percentage (used by BuySection bars + RulesTab table)
 *   rollRange — the 0-99 range that maps to this tier (shown in Rulebook)
 */

export const RARITIES = [
  {
    id:        0,
    key:       'common',
    label:     'Common',
    icon:      '🪨',
    color:     'var(--common)',
    pct:       60,           // ← must be 'pct' — BuySection and RulesTab read r.pct
    rollRange: '0 – 59',
    powerMin:  1,
    powerMax:  10,
  },
  {
    id:        1,
    key:       'rare',
    label:     'Rare',
    icon:      '💧',
    color:     'var(--rare)',
    pct:       25,
    rollRange: '60 – 84',
    powerMin:  11,
    powerMax:  25,
  },
  {
    id:        2,
    key:       'epic',
    label:     'Epic',
    icon:      '🔮',
    color:     'var(--epic)',
    pct:       12,
    rollRange: '85 – 96',
    powerMin:  26,
    powerMax:  40,
  },
  {
    id:        3,
    key:       'legendary',
    label:     'Legendary',
    icon:      '⭐',
    color:     'var(--legendary)',
    pct:       3,
    rollRange: '97 – 99',
    powerMin:  41,
    powerMax:  50,
  },
]

export function getRarity(id)      { return RARITIES[id] ?? RARITIES[0] }
export function getRarityKey(id)   { return getRarity(id).key }
export function getRarityLabel(id) { return getRarity(id).label }
export function getRarityIcon(id)  { return getRarity(id).icon }
export function getRarityColor(id) { return getRarity(id).color }