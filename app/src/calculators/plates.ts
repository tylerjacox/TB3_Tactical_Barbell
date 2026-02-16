// Plate Loading Calculator — Greedy Algorithm (PRD 5.2)
import type { PlateInventory } from '../types';

export interface PlateResult {
  plates: { weight: number; count: number }[];
  displayText: string;
  achievable: boolean;
  isBarOnly: boolean;
  isBodyweightOnly: boolean;
  isBelowBar: boolean;
  nearestAchievable?: number;
}

export function calculateBarbellPlates(
  totalWeight: number,
  barbellWeight: number,
  inventory: PlateInventory,
): PlateResult {
  // Guard: negative or zero
  if (totalWeight <= 0) {
    return {
      plates: [],
      displayText: 'Not achievable',
      achievable: false,
      isBarOnly: false,
      isBodyweightOnly: false,
      isBelowBar: false,
    };
  }

  // Bar only
  if (totalWeight === barbellWeight) {
    return {
      plates: [],
      displayText: 'Bar only',
      achievable: true,
      isBarOnly: true,
      isBodyweightOnly: false,
      isBelowBar: false,
    };
  }

  // Below bar
  if (totalWeight < barbellWeight) {
    return {
      plates: [],
      displayText: 'Weight is below bar weight',
      achievable: false,
      isBarOnly: false,
      isBodyweightOnly: false,
      isBelowBar: true,
    };
  }

  const perSide = Math.round(((totalWeight - barbellWeight) / 2) * 100) / 100;
  return greedyPlateCalc(perSide, inventory, 'per side');
}

export function calculateBeltPlates(
  totalWeight: number,
  inventory: PlateInventory,
): PlateResult {
  if (totalWeight <= 0) {
    return {
      plates: [],
      displayText: 'Bodyweight only',
      achievable: true,
      isBarOnly: false,
      isBodyweightOnly: true,
      isBelowBar: false,
    };
  }

  return greedyPlateCalc(totalWeight, inventory, 'on belt');
}

function greedyPlateCalc(
  targetWeight: number,
  inventory: PlateInventory,
  label: string,
): PlateResult {
  const sortedPlates = [...inventory.plates].sort((a, b) => b.weight - a.weight);
  const result: { weight: number; count: number }[] = [];
  let remaining = Math.round(targetWeight * 100) / 100;
  let achieved = 0;

  for (const plate of sortedPlates) {
    if (plate.available <= 0 || plate.weight > remaining) continue;
    const count = Math.min(Math.floor(remaining / plate.weight), plate.available);
    if (count > 0) {
      result.push({ weight: plate.weight, count });
      const used = Math.round(plate.weight * count * 100) / 100;
      remaining = Math.round((remaining - used) * 100) / 100;
      achieved += used;
    }
  }

  if (remaining > 0.001) {
    // Not achievable — find nearest
    const nearest = findNearestAchievable(targetWeight, inventory);
    const parts = result.map((p) =>
      p.count > 1 ? `${p.weight} x${p.count}` : `${p.weight}`,
    );
    return {
      plates: result,
      displayText: `Not achievable with current plates`,
      achievable: false,
      isBarOnly: false,
      isBodyweightOnly: false,
      isBelowBar: false,
      nearestAchievable: nearest,
    };
  }

  const parts = result.map((p) =>
    p.count > 1 ? `${p.weight} x${p.count}` : `${p.weight}`,
  );
  const displayText = parts.length > 0 ? `${parts.join('  ')}  ${label}` : label;

  return {
    plates: result,
    displayText,
    achievable: true,
    isBarOnly: false,
    isBodyweightOnly: false,
    isBelowBar: false,
  };
}

function findNearestAchievable(target: number, inventory: PlateInventory): number {
  const sortedPlates = [...inventory.plates].sort((a, b) => b.weight - a.weight);

  // Try target-1, target+1, target-2, target+2, etc. (in 0.25 increments)
  for (let offset = 0.25; offset <= 50; offset += 0.25) {
    for (const dir of [-1, 1]) {
      const candidate = Math.round((target + dir * offset) * 100) / 100;
      if (candidate < 0) continue;
      let rem = candidate;
      let achievable = true;
      for (const plate of sortedPlates) {
        if (plate.available <= 0 || plate.weight > rem) continue;
        const count = Math.min(Math.floor(rem / plate.weight), plate.available);
        rem = Math.round((rem - plate.weight * count) * 100) / 100;
      }
      if (rem < 0.001) return candidate;
    }
  }
  return 0;
}
