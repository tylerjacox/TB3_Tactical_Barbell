import { LIFT_NAMES } from '../types';
import { currentLifts } from '../state';
import { IconCheck } from './Icons';

export function LiftSelector({
  selected,
  onChange,
  min,
  max,
  label,
}: {
  selected: string[];
  onChange: (lifts: string[]) => void;
  min: number;
  max: number;
  label: string;
}) {
  const liftsWithMax = currentLifts.value;
  const liftNames = liftsWithMax.map((l) => l.name);

  function toggle(name: string) {
    if (selected.includes(name)) {
      if (selected.length > min) {
        onChange(selected.filter((n) => n !== name));
      }
    } else {
      if (selected.length < max) {
        onChange([...selected, name]);
      }
    }
  }

  return (
    <div class="lift-selector" role="group" aria-label={label}>
      <div class="card-title">{label} (select {min}-{max})</div>
      {LIFT_NAMES.map((name) => {
        const hasMax = liftNames.includes(name);
        const isSelected = selected.includes(name);
        return (
          <button
            key={name}
            class={`lift-option${isSelected ? ' selected' : ''}`}
            role="checkbox"
            aria-checked={isSelected}
            disabled={!hasMax}
            onClick={() => hasMax && toggle(name)}
          >
            <span class="lift-check">
              {isSelected && <IconCheck />}
            </span>
            <span>
              {name}
              {!hasMax && <span class="text-muted"> (no 1RM set)</span>}
            </span>
          </button>
        );
      })}
    </div>
  );
}
