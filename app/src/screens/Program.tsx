import { useState } from 'preact/hooks';
import { appData, updateAppData, currentLifts } from '../state';
import type { ActiveProgram, TemplateId } from '../types';
import { ALL_TEMPLATES, getTemplate } from '../templates/definitions';
import { generateSchedule } from '../templates/schedule';
import { TemplateCard } from '../components/TemplateCard';
import { LiftSelector } from '../components/LiftSelector';
import { WeekSchedule } from '../components/WeekSchedule';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { navigate } from '../router';

export function Program() {
  const { activeProgram, computedSchedule } = appData.value;
  const lifts = currentLifts.value;
  const [showTemplates, setShowTemplates] = useState(!activeProgram);
  const [selectedTemplate, setSelectedTemplate] = useState<TemplateId | null>(null);
  const [liftSelections, setLiftSelections] = useState<Record<string, string[]>>({});
  const [confirmSwitch, setConfirmSwitch] = useState(false);

  const template = activeProgram ? getTemplate(activeProgram.templateId) : null;
  const newTemplate = selectedTemplate ? getTemplate(selectedTemplate) : null;

  async function startProgram() {
    if (!selectedTemplate) return;

    const tmpl = getTemplate(selectedTemplate)!;
    const selections: Record<string, string[]> = {};
    if (tmpl.liftSlots) {
      for (const slot of tmpl.liftSlots) {
        selections[slot.cluster] = liftSelections[slot.cluster] || slot.defaults;
      }
    }

    const program: ActiveProgram = {
      templateId: selectedTemplate,
      startDate: new Date().toISOString().slice(0, 10),
      currentWeek: 1,
      currentSession: 1,
      liftSelections: selections,
      lastModified: new Date().toISOString(),
    };

    const schedule = generateSchedule(program, lifts, appData.value.profile);

    await updateAppData((d) => ({
      ...d,
      activeProgram: program,
      computedSchedule: schedule,
      activeSession: null,
    }));

    setShowTemplates(false);
    setSelectedTemplate(null);
  }

  function handleSelectTemplate(id: TemplateId) {
    if (activeProgram && !showTemplates) {
      setSelectedTemplate(id);
      setConfirmSwitch(true);
    } else {
      setSelectedTemplate(id);
    }
  }

  // Show active program schedule
  if (activeProgram && computedSchedule && !showTemplates) {
    return (
      <div class="screen">
        <div class="screen-header">
          <h1>Program</h1>
        </div>

        <div class="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: 20, fontWeight: 700 }}>{template?.name}</div>
              <div style={{ fontSize: 14, color: 'var(--muted)' }}>
                Week {activeProgram.currentWeek} of {template?.durationWeeks}
              </div>
            </div>
            <button
              class="btn btn-ghost"
              onClick={() => setShowTemplates(true)}
            >
              Switch
            </button>
          </div>
        </div>

        {computedSchedule.weeks.map((week) => (
          <WeekSchedule
            key={week.weekNumber}
            week={week}
            isCurrent={week.weekNumber === activeProgram.currentWeek}
            defaultOpen={week.weekNumber === activeProgram.currentWeek}
          />
        ))}
      </div>
    );
  }

  // Show template browser
  return (
    <div class="screen">
      <div class="screen-header">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h1>Program</h1>
          {activeProgram && (
            <button class="btn btn-ghost" onClick={() => setShowTemplates(false)}>
              Back
            </button>
          )}
        </div>
      </div>

      {lifts.length === 0 && (
        <div class="card" style={{ textAlign: 'center' }}>
          <p style={{ color: 'var(--muted)', marginBottom: 12 }}>
            Enter your lifts first to see calculated weights.
          </p>
          <button class="btn btn-primary" onClick={() => navigate('profile')}>
            Enter Lifts
          </button>
        </div>
      )}

      <div role="radiogroup" aria-label="Template selection">
        {ALL_TEMPLATES.map((t) => (
          <TemplateCard
            key={t.id}
            template={t}
            selected={selectedTemplate === t.id}
            onSelect={() => handleSelectTemplate(t.id)}
          />
        ))}
      </div>

      {newTemplate?.requiresLiftSelection && newTemplate.liftSlots && (
        <div style={{ marginTop: 16 }}>
          {newTemplate.liftSlots.map((slot) => (
            <LiftSelector
              key={slot.cluster}
              selected={liftSelections[slot.cluster] || slot.defaults}
              onChange={(l) => setLiftSelections({ ...liftSelections, [slot.cluster]: l })}
              min={slot.minLifts}
              max={slot.maxLifts}
              label={slot.label}
            />
          ))}
        </div>
      )}

      {selectedTemplate && (
        <button
          class="btn btn-primary"
          style={{ marginTop: 16 }}
          onClick={() => {
            if (activeProgram) {
              setConfirmSwitch(true);
            } else {
              startProgram();
            }
          }}
        >
          Start {newTemplate?.name || 'Program'}
        </button>
      )}

      {confirmSwitch && (
        <ConfirmDialog
          title="Switch Program?"
          message={`Starting a new program will end your current ${template?.name} cycle (Week ${activeProgram?.currentWeek} of ${template?.durationWeeks}). Session history is preserved. Continue?`}
          confirmLabel="Switch"
          onConfirm={() => {
            setConfirmSwitch(false);
            startProgram();
          }}
          onCancel={() => {
            setConfirmSwitch(false);
            setSelectedTemplate(null);
          }}
        />
      )}
    </div>
  );
}
