import type { PlateInventory } from '../types';
import { IconPlus, IconMinus } from './Icons';

export function PlateInventoryEditor({
  inventory,
  label,
  onChange,
}: {
  inventory: PlateInventory;
  label: string;
  onChange: (updated: PlateInventory) => void;
}) {
  function updateCount(index: number, delta: number) {
    const plates = inventory.plates.map((p, i) => {
      if (i !== index) return p;
      const newCount = Math.max(0, Math.min(20, p.available + delta));
      return { ...p, available: newCount };
    });
    onChange({ plates });
  }

  return (
    <div>
      <div class="card-title">{label}</div>
      {inventory.plates.map((plate, i) => (
        <div key={plate.weight} class="settings-row">
          <span class="settings-row-label">{plate.weight} lb</span>
          <div class="stepper">
            <button
              class="stepper-btn"
              onClick={() => updateCount(i, -1)}
              disabled={plate.available <= 0}
              aria-label={`Decrease ${plate.weight} pound plates`}
            >
              <IconMinus />
            </button>
            <span class="stepper-value">{plate.available}</span>
            <button
              class="stepper-btn"
              onClick={() => updateCount(i, 1)}
              disabled={plate.available >= 20}
              aria-label={`Increase ${plate.weight} pound plates`}
            >
              <IconPlus />
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}
