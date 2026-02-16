import { useState, useEffect } from 'preact/hooks';
import { appData, updateAppData, isFirstLaunch } from '../state';
import { generateId } from '../types';
import type { ActiveProgram, OneRepMaxTest, TemplateId, ComputedSchedule } from '../types';
import { calculateOneRepMax, calculateTrainingMax } from '../calculators/oneRepMax';
import { getTemplate } from '../templates/definitions';
import { generateSchedule } from '../templates/schedule';
import { getCurrentLifts } from '../state';
import { navigate } from '../router';
import { Step1Lifts, createDefaultLiftInputs } from './onboarding/Step1Lifts';
import type { LiftInput } from './onboarding/Step1Lifts';
import { Step2Template } from './onboarding/Step2Template';
import { Step3Preview } from './onboarding/Step3Preview';
import { Step4Start } from './onboarding/Step4Start';

export function Onboarding() {
  const [step, setStep] = useState(1);
  const [liftInputs, setLiftInputs] = useState<LiftInput[]>(createDefaultLiftInputs());
  const [selectedTemplate, setSelectedTemplate] = useState<TemplateId | null>(null);
  const [liftSelections, setLiftSelections] = useState<Record<string, string[]>>({});
  const [startDate, setStartDate] = useState(new Date().toISOString().slice(0, 10));
  const [previewSchedule, setPreviewSchedule] = useState<ComputedSchedule | null>(null);

  // Generate preview when reaching step 3
  useEffect(() => {
    if (step === 3 && selectedTemplate) {
      generatePreview();
    }
  }, [step]);

  function generatePreview() {
    if (!selectedTemplate) return;
    const template = getTemplate(selectedTemplate);
    if (!template) return;

    // Save lift inputs first
    saveLiftInputs();

    const data = appData.value;
    const lifts = getCurrentLifts(data);
    const program: ActiveProgram = {
      templateId: selectedTemplate,
      startDate,
      currentWeek: 1,
      currentSession: 1,
      liftSelections: resolveLiftSelections(selectedTemplate, liftSelections),
      lastModified: new Date().toISOString(),
    };

    try {
      const schedule = generateSchedule(program, lifts, data.profile);
      setPreviewSchedule(schedule);
    } catch {
      setPreviewSchedule(null);
    }
  }

  function saveLiftInputs() {
    const tests: OneRepMaxTest[] = [];
    const profile = appData.value.profile;

    for (const input of liftInputs) {
      const w = parseFloat(input.weight);
      const r = parseInt(input.reps, 10);
      if (!w || w < 1 || !r || r < 1) continue;

      const oneRepMax = calculateOneRepMax(w, r);
      const workingMax = profile.maxType === 'training'
        ? calculateTrainingMax(oneRepMax)
        : oneRepMax;

      tests.push({
        id: generateId(),
        date: new Date().toISOString(),
        liftName: input.name,
        weight: w,
        reps: r,
        calculatedMax: Math.round(oneRepMax * 100) / 100,
        maxType: profile.maxType,
        workingMax: Math.round(workingMax * 100) / 100,
        lastModified: new Date().toISOString(),
      });
    }

    if (tests.length > 0) {
      updateAppData((d) => ({
        ...d,
        maxTestHistory: [...d.maxTestHistory, ...tests],
      }));
    }
  }

  async function handleFinish() {
    if (!selectedTemplate) return;

    // Save lifts if not already saved
    if (appData.value.maxTestHistory.length === 0) {
      saveLiftInputs();
    }

    const data = appData.value;
    const lifts = getCurrentLifts(data);
    const program: ActiveProgram = {
      templateId: selectedTemplate,
      startDate,
      currentWeek: 1,
      currentSession: 1,
      liftSelections: resolveLiftSelections(selectedTemplate, liftSelections),
      lastModified: new Date().toISOString(),
    };

    const schedule = generateSchedule(program, lifts, data.profile);

    await updateAppData((d) => ({
      ...d,
      activeProgram: program,
      computedSchedule: schedule,
    }));

    isFirstLaunch.value = false;
    navigate('home');
  }

  function canContinue(): boolean {
    switch (step) {
      case 1: return true; // All lifts optional
      case 2: return selectedTemplate !== null;
      case 3: return true;
      case 4: return true;
      default: return false;
    }
  }

  return (
    <div class="onboarding">
      {/* Step indicator */}
      <div class="step-indicator" role="navigation" aria-label={`Step ${step} of 4`}>
        {[1, 2, 3, 4].map((s) => (
          <div
            key={s}
            class={`step-dot${s === step ? ' active' : s < step ? ' completed' : ''}`}
            aria-current={s === step ? 'step' : undefined}
          />
        ))}
      </div>

      {/* Content */}
      <div class="onboarding-content">
        {step === 1 && <Step1Lifts liftInputs={liftInputs} onChange={setLiftInputs} />}
        {step === 2 && (
          <Step2Template
            selectedTemplate={selectedTemplate}
            onSelect={setSelectedTemplate}
            liftSelections={liftSelections}
            onLiftSelectionsChange={setLiftSelections}
          />
        )}
        {step === 3 && <Step3Preview schedule={previewSchedule} />}
        {step === 4 && <Step4Start startDate={startDate} onDateChange={setStartDate} />}
      </div>

      {/* Footer */}
      <div class="onboarding-footer">
        {step > 1 && (
          <button
            class="btn btn-secondary"
            style={{ flex: 1 }}
            onClick={() => setStep(step - 1)}
          >
            Back
          </button>
        )}
        {step < 4 ? (
          <button
            class="btn btn-primary"
            style={{ flex: step > 1 ? 2 : 1 }}
            onClick={() => {
              if (step === 1) saveLiftInputs();
              setStep(step + 1);
            }}
            disabled={!canContinue()}
          >
            Continue
          </button>
        ) : (
          <button
            class="btn btn-primary btn-large"
            style={{ flex: 2 }}
            onClick={handleFinish}
          >
            Start Training
          </button>
        )}
      </div>
    </div>
  );
}

function resolveLiftSelections(
  templateId: TemplateId,
  selections: Record<string, string[]>,
): Record<string, string[]> {
  const template = getTemplate(templateId);
  if (!template?.liftSlots) return {};

  const result: Record<string, string[]> = {};
  for (const slot of template.liftSlots) {
    result[slot.cluster] = selections[slot.cluster] || slot.defaults;
  }
  return result;
}
