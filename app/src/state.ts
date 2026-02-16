// Global Preact Signals state management
import { signal, computed } from '@preact/signals';
import type { AppData, DerivedLiftEntry } from './types';
import { createDefaultAppData } from './types';
import { loadAppData, saveAppData } from './services/storage';
import { calculateOneRepMax, calculateTrainingMax } from './calculators/oneRepMax';

export const appData = signal<AppData>(createDefaultAppData());
export const isLoading = signal(true);
export const isFirstLaunch = signal(false);

// Derived: current lift values from maxTestHistory
export const currentLifts = computed<DerivedLiftEntry[]>(() => {
  return getCurrentLifts(appData.value);
});

export function getCurrentLifts(data: AppData): DerivedLiftEntry[] {
  const { maxTestHistory, profile } = data;
  if (!maxTestHistory.length) return [];

  // Group by lift name, take most recent per lift
  const byLift = new Map<string, typeof maxTestHistory[0]>();
  for (const test of maxTestHistory) {
    const existing = byLift.get(test.liftName);
    if (!existing || new Date(test.date).getTime() > new Date(existing.date).getTime()) {
      byLift.set(test.liftName, test);
    }
  }

  const entries: DerivedLiftEntry[] = [];
  for (const [name, test] of byLift) {
    const oneRepMax = calculateOneRepMax(test.weight, test.reps);
    const workingMax =
      profile.maxType === 'training'
        ? calculateTrainingMax(oneRepMax)
        : oneRepMax;

    entries.push({
      name,
      weight: test.weight,
      reps: test.reps,
      oneRepMax,
      workingMax,
      isBodyweight: name === 'Weighted Pull-up',
      testDate: test.date,
    });
  }

  return entries;
}

export async function initApp(): Promise<void> {
  isLoading.value = true;
  try {
    const data = await loadAppData();
    appData.value = data;
    isFirstLaunch.value = data.maxTestHistory.length === 0 && !data.activeProgram;
  } catch (e) {
    console.error('Failed to load app data:', e);
    appData.value = createDefaultAppData();
    isFirstLaunch.value = true;
  }
  isLoading.value = false;
}

export async function updateAppData(
  updater: (data: AppData) => AppData,
): Promise<void> {
  const updated = updater(appData.value);
  appData.value = updated;
  await saveAppData(updated);
}
