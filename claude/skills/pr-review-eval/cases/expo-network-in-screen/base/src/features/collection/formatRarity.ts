const LABELS = ['Common', 'Uncommon', 'Rare', 'Very rare', 'Legendary'];

// Rarity is stored 1–5; out-of-range values come from older catalogue versions and show as the nearest label.
export function formatRarity(rarity: number): string {
  const index = Math.min(Math.max(Math.round(rarity), 1), LABELS.length) - 1;
  return LABELS[index];
}
