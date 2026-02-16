import { useState } from 'preact/hooks';
import { LIFT_NAMES } from '../../types';

export interface LiftInput {
  name: string;
  weight: string;
  reps: string;
}

export function Step1Lifts({
  liftInputs,
  onChange,
}: {
  liftInputs: LiftInput[];
  onChange: (inputs: LiftInput[]) => void;
}) {
  function updateLift(index: number, field: 'weight' | 'reps', value: string) {
    const updated = liftInputs.map((l, i) =>
      i === index ? { ...l, [field]: value } : l,
    );
    onChange(updated);
  }

  return (
    <div>
      <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 8 }}>Enter Your Lifts</h2>
      <p style={{ color: 'var(--muted)', fontSize: 15, lineHeight: 1.4, marginBottom: 24 }}>
        Enter a recent heavy set for each lift you train. We'll calculate your max. All lifts are optional.
      </p>

      {liftInputs.map((lift, i) => (
        <fieldset key={lift.name} style={{ marginBottom: 20 }}>
          <legend>{lift.name} — enter a recent heavy set</legend>
          <div style={{ display: 'flex', gap: 8 }}>
            <div class="field" style={{ flex: 1 }}>
              <label for={`weight-${i}`}>Weight (lb)</label>
              <input
                id={`weight-${i}`}
                type="text"
                inputMode="decimal"
                value={lift.weight}
                onInput={(e) => updateLift(i, 'weight', (e.target as HTMLInputElement).value)}
                placeholder="e.g. 225"
              />
            </div>
            <div class="field" style={{ flex: 1 }}>
              <label for={`reps-${i}`}>Reps</label>
              <input
                id={`reps-${i}`}
                type="text"
                inputMode="numeric"
                value={lift.reps}
                onInput={(e) => updateLift(i, 'reps', (e.target as HTMLInputElement).value)}
                placeholder="e.g. 5"
              />
            </div>
          </div>
        </fieldset>
      ))}
    </div>
  );
}

export function createDefaultLiftInputs(): LiftInput[] {
  return LIFT_NAMES.map((name) => ({ name, weight: '', reps: '' }));
}
