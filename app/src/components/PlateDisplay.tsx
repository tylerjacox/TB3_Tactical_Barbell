import type { PlateResult } from '../calculators/plates';

/** Competition plate colors */
const PLATE_COLORS: Record<number, string> = {
  45: '#C62828',   // red
  35: '#F9A825',   // yellow
  25: '#7B1FA2',   // purple
  10: '#E65100',   // orange
  5: '#42A5F5',    // light blue
  2.5: '#66BB6A',  // light green
  1.25: '#EEEEEE', // white
};

/** Plate height as percentage of max (45lb = 100%) — used as width in barbell view */
const PLATE_HEIGHT: Record<number, number> = {
  45: 100,
  35: 88,
  25: 76,
  10: 58,
  5: 46,
  2.5: 38,
  1.25: 32,
};

/** Plate width (thickness) in px for barbell view */
const PLATE_WIDTH: Record<number, number> = {
  45: 10,
  35: 9,
  25: 8,
  10: 6,
  5: 5,
  2.5: 4,
  1.25: 3,
};

/** Plate width for belt view (horizontal width, proportional to weight) */
const BELT_PLATE_WIDTH: Record<number, number> = {
  45: 40,
  35: 36,
  25: 32,
  10: 26,
  5: 22,
  2.5: 18,
  1.25: 16,
};

/** Plate thickness for belt view (vertical height) */
const BELT_PLATE_THICKNESS: Record<number, number> = {
  45: 10,
  35: 9,
  25: 8,
  10: 6,
  5: 5,
  2.5: 4,
  1.25: 3,
};

export function PlateDisplay({ result, isBodyweight }: { result: PlateResult; isBodyweight?: boolean }) {
  if (result.isBarOnly) {
    return <span class="plate-status-text">Bar only</span>;
  }
  if (result.isBodyweightOnly) {
    return <span class="plate-status-text">Bodyweight only</span>;
  }
  if (result.isBelowBar) {
    return <span class="plate-status-text text-error">Weight is below bar weight</span>;
  }
  if (!result.achievable) {
    return (
      <span class="plate-status-text text-error">
        Not achievable with current plates
        {result.nearestAchievable ? ` (nearest: ${result.nearestAchievable} lb)` : ''}
      </span>
    );
  }

  if (result.plates.length === 0) return null;

  // Expand grouped plates into individual entries, heaviest first
  const expanded: number[] = [];
  for (const p of result.plates) {
    for (let i = 0; i < p.count; i++) {
      expanded.push(p.weight);
    }
  }

  const label = isBodyweight ? 'on belt' : 'per side';
  const accessibleLabel = formatPlateAccessibleLabel(result, label);

  if (isBodyweight) {
    return (
      <div class="barbell-diagram" aria-label={accessibleLabel} role="img">
        <BeltVisual plates={expanded} />
        <PlateSummary plates={result.plates} label={label} />
      </div>
    );
  }

  return (
    <div class="barbell-diagram" aria-label={accessibleLabel} role="img">
      <BarbellVisual plates={expanded} />
      <PlateSummary plates={result.plates} label={label} />
    </div>
  );
}

/** Barbell: horizontal bar with plates on both sides, heaviest near collar */
function BarbellVisual({ plates }: { plates: number[] }) {
  // Left side: reverse so heaviest is closest to center
  const leftPlates = [...plates].reverse();
  const rightPlates = [...plates];
  const maxHeight = 44;
  const barHeight = 6;

  return (
    <div class="barbell-visual">
      <div class="barbell-plates barbell-plates-left">
        {leftPlates.map((weight, i) => {
          const h = Math.round((PLATE_HEIGHT[weight] ?? 50) / 100 * maxHeight);
          const w = PLATE_WIDTH[weight] ?? 6;
          const color = PLATE_COLORS[weight] ?? '#888';
          return (
            <div
              key={`l${i}`}
              class="barbell-plate"
              style={{ height: `${h}px`, width: `${w}px`, background: color }}
            />
          );
        })}
      </div>
      <div class="barbell-collar" />
      <div class="barbell-bar" style={{ height: `${barHeight}px` }} />
      <div class="barbell-collar" />
      <div class="barbell-plates barbell-plates-right">
        {rightPlates.map((weight, i) => {
          const h = Math.round((PLATE_HEIGHT[weight] ?? 50) / 100 * maxHeight);
          const w = PLATE_WIDTH[weight] ?? 6;
          const color = PLATE_COLORS[weight] ?? '#888';
          return (
            <div
              key={`r${i}`}
              class="barbell-plate"
              style={{ height: `${h}px`, width: `${w}px`, background: color }}
            />
          );
        })}
      </div>
    </div>
  );
}

/** Belt: chain hanging down with plates stacked vertically, heaviest on top */
function BeltVisual({ plates }: { plates: number[] }) {
  // Heaviest on top (closest to belt), lightest at bottom
  const ordered = [...plates]; // already heaviest-first

  return (
    <div class="belt-visual">
      {/* Chain */}
      <div class="belt-chain" />
      {/* Plates stacked vertically */}
      <div class="belt-plates">
        {ordered.map((weight, i) => {
          const w = BELT_PLATE_WIDTH[weight] ?? 24;
          const h = BELT_PLATE_THICKNESS[weight] ?? 6;
          const color = PLATE_COLORS[weight] ?? '#888';
          return (
            <div
              key={i}
              class="belt-plate"
              style={{ width: `${w}px`, height: `${h}px`, background: color }}
            />
          );
        })}
      </div>
      {/* Pin at bottom */}
      <div class="belt-pin" />
    </div>
  );
}

/** Color-coded legend below the diagram */
function PlateSummary({ plates, label }: { plates: { weight: number; count: number }[]; label: string }) {
  return (
    <div class="barbell-plate-summary">
      {plates.map((p, i) => {
        const color = PLATE_COLORS[p.weight] ?? '#888';
        return (
          <span key={i} class="barbell-plate-label">
            <span class="barbell-plate-dot" style={{ background: color }} />
            {p.count > 1 ? `${p.weight} x${p.count}` : `${p.weight}`}
          </span>
        );
      })}
      <span class="barbell-per-side">{label}</span>
    </div>
  );
}

function formatPlateAccessibleLabel(result: PlateResult, label: string): string {
  const parts = result.plates.map((p) => {
    if (p.count > 1) return `${p.count} ${p.weight}-pound plates`;
    return `one ${p.weight}-pound plate`;
  });
  return `${label}: ${parts.join(', ')}`;
}
