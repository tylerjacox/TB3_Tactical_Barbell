import { useState } from 'preact/hooks';
import type { TemplateDef } from '../../templates/definitions';
import { ALL_TEMPLATES, getTemplatesForDays } from '../../templates/definitions';
import { TemplateCard } from '../../components/TemplateCard';
import { LiftSelector } from '../../components/LiftSelector';
import type { TemplateId } from '../../types';

export function Step2Template({
  selectedTemplate,
  onSelect,
  liftSelections,
  onLiftSelectionsChange,
}: {
  selectedTemplate: TemplateId | null;
  onSelect: (id: TemplateId) => void;
  liftSelections: Record<string, string[]>;
  onLiftSelectionsChange: (selections: Record<string, string[]>) => void;
}) {
  const [days, setDays] = useState<number | null>(null);
  const [showAll, setShowAll] = useState(false);

  const templates = showAll || days === null
    ? ALL_TEMPLATES
    : getTemplatesForDays(days);

  const selected = ALL_TEMPLATES.find((t) => t.id === selectedTemplate);

  return (
    <div>
      <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 8 }}>Choose Your Template</h2>

      {/* Day recommendation */}
      {!showAll && (
        <div style={{ marginBottom: 20 }}>
          <p style={{ color: 'var(--muted)', fontSize: 15, marginBottom: 12 }}>
            How many days per week can you lift?
          </p>
          <div style={{ display: 'flex', gap: 8 }}>
            {[2, 3, 4].map((d) => (
              <button
                key={d}
                class={`btn ${days === d ? 'btn-primary' : 'btn-secondary'}`}
                style={{ flex: 1, minHeight: 44 }}
                onClick={() => setDays(d)}
              >
                {d} days
              </button>
            ))}
          </div>
          <button
            class="btn btn-ghost"
            style={{ width: '100%', marginTop: 8 }}
            onClick={() => setShowAll(true)}
          >
            Show all templates
          </button>
        </div>
      )}

      {/* Template list */}
      <div role="radiogroup" aria-label="Template selection">
        {templates.map((t) => (
          <TemplateCard
            key={t.id}
            template={t}
            selected={selectedTemplate === t.id}
            onSelect={() => onSelect(t.id)}
          />
        ))}
      </div>

      {/* Lift selection for selected template */}
      {selected?.requiresLiftSelection && selected.liftSlots && (
        <div style={{ marginTop: 16 }}>
          {selected.liftSlots.map((slot) => (
            <LiftSelector
              key={slot.cluster}
              selected={liftSelections[slot.cluster] || slot.defaults}
              onChange={(lifts) => onLiftSelectionsChange({ ...liftSelections, [slot.cluster]: lifts })}
              min={slot.minLifts}
              max={slot.maxLifts}
              label={slot.label}
            />
          ))}
        </div>
      )}
    </div>
  );
}
