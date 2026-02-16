// Template Definitions — All 7 TB3 templates as data objects (PRD 5.3)
import type { TemplateId } from '../types';

export interface TemplateDef {
  id: TemplateId;
  name: string;
  description: string;
  durationWeeks: number;
  sessionsPerWeek: number;
  requiresLiftSelection: boolean;
  liftSlots?: LiftSlotDef[];
  hasEndurance: boolean;
  hasSetRange: boolean;
  hideRestTimer?: boolean;
  weeks: WeekDef[];
  sessionDefs: SessionDef[];
  recommendedDays: number[];
}

export interface WeekDef {
  weekNumber: number;
  percentage: number;
  setsRange: [number, number];
  repsPerSet: number | number[];
}

export interface SessionDef {
  sessionNumber: number;
  type: 'strength' | 'endurance';
  lifts?: string[]; // Lift names or slot references like 'cluster' or 'A' / 'B'
  liftSource?: 'fixed' | 'cluster' | 'A' | 'B';
  enduranceDuration?: string;
  percentageOverride?: number; // For Zulu cluster differences
  setsOverride?: [number, number];
  repsOverride?: number | number[];
}

export interface LiftSlotDef {
  cluster: string;
  label: string;
  minLifts: number;
  maxLifts: number;
  defaults: string[];
}

// --- Template Definitions ---

export const OPERATOR: TemplateDef = {
  id: 'operator',
  name: 'Operator',
  description: 'Balanced strength + endurance. 3 strength days, 3 cardio days/week. 6-week cycle.',
  durationWeeks: 6,
  sessionsPerWeek: 6,
  requiresLiftSelection: false,
  hasEndurance: true,
  hasSetRange: true,
  recommendedDays: [3],
  weeks: [
    { weekNumber: 1, percentage: 70, setsRange: [3, 5], repsPerSet: 5 },
    { weekNumber: 2, percentage: 80, setsRange: [3, 5], repsPerSet: 5 },
    { weekNumber: 3, percentage: 90, setsRange: [3, 4], repsPerSet: 3 },
    { weekNumber: 4, percentage: 75, setsRange: [3, 5], repsPerSet: 5 },
    { weekNumber: 5, percentage: 85, setsRange: [3, 5], repsPerSet: 3 },
    { weekNumber: 6, percentage: 95, setsRange: [3, 4], repsPerSet: [1, 2] },
  ],
  sessionDefs: [
    { sessionNumber: 1, type: 'strength', lifts: ['Squat', 'Bench', 'Weighted Pull-up'], liftSource: 'fixed' },
    { sessionNumber: 2, type: 'endurance' },
    { sessionNumber: 3, type: 'strength', lifts: ['Squat', 'Bench', 'Weighted Pull-up'], liftSource: 'fixed' },
    { sessionNumber: 4, type: 'endurance' },
    { sessionNumber: 5, type: 'strength', lifts: ['Squat', 'Bench', 'Deadlift'], liftSource: 'fixed' },
    { sessionNumber: 6, type: 'endurance' },
  ],
};

// Endurance durations for Operator by week (sessions 2/4 and session 6)
export const OPERATOR_ENDURANCE: Record<number, { sessions24: string; session6: string }> = {
  1: { sessions24: '30-60', session6: '60-90' },
  2: { sessions24: '30-60', session6: '60-90' },
  3: { sessions24: '30-60', session6: '60-90' },
  4: { sessions24: '30', session6: '30' },
  5: { sessions24: '60-90', session6: '90-120' },
  6: { sessions24: '60-90', session6: '90-120' },
};

export const ZULU: TemplateDef = {
  id: 'zulu',
  name: 'Zulu',
  description: '4 strength sessions/week. A/B split with two intensity levels per week. 6-week cycle.',
  durationWeeks: 6,
  sessionsPerWeek: 4,
  requiresLiftSelection: true,
  hasEndurance: false,
  hasSetRange: false,
  recommendedDays: [4],
  liftSlots: [
    { cluster: 'A', label: 'A Day', minLifts: 2, maxLifts: 3, defaults: ['Military Press', 'Squat', 'Weighted Pull-up'] },
    { cluster: 'B', label: 'B Day', minLifts: 2, maxLifts: 3, defaults: ['Bench', 'Deadlift'] },
  ],
  weeks: [
    { weekNumber: 1, percentage: 70, setsRange: [3, 3], repsPerSet: 5 },
    { weekNumber: 2, percentage: 80, setsRange: [3, 3], repsPerSet: 5 },
    { weekNumber: 3, percentage: 90, setsRange: [3, 3], repsPerSet: 3 },
    { weekNumber: 4, percentage: 70, setsRange: [3, 3], repsPerSet: 5 },
    { weekNumber: 5, percentage: 80, setsRange: [3, 3], repsPerSet: 5 },
    { weekNumber: 6, percentage: 90, setsRange: [3, 3], repsPerSet: 3 },
  ],
  sessionDefs: [
    { sessionNumber: 1, type: 'strength', liftSource: 'A' },  // A1 — Cluster One
    { sessionNumber: 2, type: 'strength', liftSource: 'B' },  // B1 — Cluster One
    { sessionNumber: 3, type: 'strength', liftSource: 'A' },  // A2 — Cluster Two
    { sessionNumber: 4, type: 'strength', liftSource: 'B' },  // B2 — Cluster Two
  ],
};

// Zulu cluster percentages per week
export const ZULU_CLUSTER_PERCENTAGES: Record<number, { clusterOne: number; clusterTwo: number }> = {
  1: { clusterOne: 70, clusterTwo: 75 },
  2: { clusterOne: 80, clusterTwo: 80 },
  3: { clusterOne: 90, clusterTwo: 90 },
  4: { clusterOne: 70, clusterTwo: 75 },
  5: { clusterOne: 80, clusterTwo: 80 },
  6: { clusterOne: 90, clusterTwo: 90 },
};

export const FIGHTER: TemplateDef = {
  id: 'fighter',
  name: 'Fighter',
  description: 'Minimal lifting. 2 sessions/week. For heavy conditioning schedules. 6-week cycle.',
  durationWeeks: 6,
  sessionsPerWeek: 2,
  requiresLiftSelection: true,
  hasEndurance: false,
  hasSetRange: true,
  recommendedDays: [2],
  liftSlots: [
    { cluster: 'cluster', label: 'Lifts', minLifts: 2, maxLifts: 3, defaults: ['Squat', 'Bench'] },
  ],
  weeks: [
    { weekNumber: 1, percentage: 75, setsRange: [3, 5], repsPerSet: 5 },
    { weekNumber: 2, percentage: 80, setsRange: [3, 5], repsPerSet: 5 },
    { weekNumber: 3, percentage: 90, setsRange: [3, 5], repsPerSet: 3 },
    { weekNumber: 4, percentage: 75, setsRange: [3, 5], repsPerSet: 5 },
    { weekNumber: 5, percentage: 80, setsRange: [3, 5], repsPerSet: 5 },
    { weekNumber: 6, percentage: 90, setsRange: [3, 5], repsPerSet: 3 },
  ],
  sessionDefs: [
    { sessionNumber: 1, type: 'strength', liftSource: 'cluster' },
    { sessionNumber: 2, type: 'strength', liftSource: 'cluster' },
  ],
};

export const GLADIATOR: TemplateDef = {
  id: 'gladiator',
  name: 'Gladiator',
  description: 'High volume. 3 sessions/week. All lifts every session. 5x5 base. 6-week cycle.',
  durationWeeks: 6,
  sessionsPerWeek: 3,
  requiresLiftSelection: true,
  hasEndurance: false,
  hasSetRange: false,
  recommendedDays: [3],
  liftSlots: [
    { cluster: 'cluster', label: 'Lifts', minLifts: 2, maxLifts: 4, defaults: ['Squat', 'Bench', 'Deadlift'] },
  ],
  weeks: [
    { weekNumber: 1, percentage: 70, setsRange: [5, 5], repsPerSet: 5 },
    { weekNumber: 2, percentage: 80, setsRange: [5, 5], repsPerSet: 5 },
    { weekNumber: 3, percentage: 90, setsRange: [5, 5], repsPerSet: 3 },
    { weekNumber: 4, percentage: 75, setsRange: [5, 5], repsPerSet: 5 },
    { weekNumber: 5, percentage: 85, setsRange: [5, 5], repsPerSet: 5 },
    { weekNumber: 6, percentage: 95, setsRange: [5, 5], repsPerSet: [3, 2, 1, 3, 2] },
  ],
  sessionDefs: [
    { sessionNumber: 1, type: 'strength', liftSource: 'cluster' },
    { sessionNumber: 2, type: 'strength', liftSource: 'cluster' },
    { sessionNumber: 3, type: 'strength', liftSource: 'cluster' },
  ],
};

export const MASS_PROTOCOL: TemplateDef = {
  id: 'mass-protocol',
  name: 'Mass Protocol',
  description: 'Hypertrophy focus. 3 sessions/week. All lifts every session. No rest minimums. 6-week cycle.',
  durationWeeks: 6,
  sessionsPerWeek: 3,
  requiresLiftSelection: true,
  hasEndurance: false,
  hasSetRange: false,
  hideRestTimer: true,
  recommendedDays: [3],
  liftSlots: [
    { cluster: 'cluster', label: 'Lifts', minLifts: 2, maxLifts: 4, defaults: ['Squat', 'Bench', 'Deadlift'] },
  ],
  weeks: [
    { weekNumber: 1, percentage: 75, setsRange: [4, 4], repsPerSet: 6 },
    { weekNumber: 2, percentage: 80, setsRange: [4, 4], repsPerSet: 5 },
    { weekNumber: 3, percentage: 90, setsRange: [4, 4], repsPerSet: 3 },
    { weekNumber: 4, percentage: 75, setsRange: [4, 4], repsPerSet: 6 },
    { weekNumber: 5, percentage: 85, setsRange: [4, 4], repsPerSet: 4 },
    { weekNumber: 6, percentage: 90, setsRange: [4, 4], repsPerSet: 3 },
  ],
  sessionDefs: [
    { sessionNumber: 1, type: 'strength', liftSource: 'cluster' },
    { sessionNumber: 2, type: 'strength', liftSource: 'cluster' },
    { sessionNumber: 3, type: 'strength', liftSource: 'cluster' },
  ],
};

export const MASS_STRENGTH: TemplateDef = {
  id: 'mass-strength',
  name: 'Mass Strength',
  description: 'Hypertrophy + strength. 4 tracked sessions per week with a dedicated deadlift day. 3-week cycle.',
  durationWeeks: 3,
  sessionsPerWeek: 4,
  requiresLiftSelection: false,
  hasEndurance: false,
  hasSetRange: false,
  recommendedDays: [3],
  weeks: [
    { weekNumber: 1, percentage: 65, setsRange: [4, 4], repsPerSet: 8 },
    { weekNumber: 2, percentage: 75, setsRange: [4, 4], repsPerSet: 6 },
    { weekNumber: 3, percentage: 80, setsRange: [4, 4], repsPerSet: 3 },
  ],
  sessionDefs: [
    { sessionNumber: 1, type: 'strength', lifts: ['Squat', 'Bench', 'Weighted Pull-up'], liftSource: 'fixed' },
    { sessionNumber: 2, type: 'strength', lifts: ['Squat', 'Bench', 'Weighted Pull-up'], liftSource: 'fixed' },
    { sessionNumber: 3, type: 'strength', lifts: ['Squat', 'Bench', 'Weighted Pull-up'], liftSource: 'fixed' },
    {
      sessionNumber: 4, type: 'strength', lifts: ['Deadlift'], liftSource: 'fixed',
      repsOverride: undefined, // Will use MASS_STRENGTH_DL_WEEKS
    },
  ],
};

// Mass Strength Deadlift day has different reps
export const MASS_STRENGTH_DL_WEEKS: Record<number, { sets: number; reps: number }> = {
  1: { sets: 4, reps: 5 },
  2: { sets: 4, reps: 5 },
  3: { sets: 1, reps: 3 },
};

export const GREY_MAN: TemplateDef = {
  id: 'grey-man',
  name: 'Grey Man',
  description: 'Low profile. 3 sessions/week. All lifts every session. 12-week cycle with progressive intensification.',
  durationWeeks: 12,
  sessionsPerWeek: 3,
  requiresLiftSelection: true,
  hasEndurance: false,
  hasSetRange: false,
  recommendedDays: [3],
  liftSlots: [
    { cluster: 'cluster', label: 'Lifts', minLifts: 2, maxLifts: 4, defaults: ['Squat', 'Bench', 'Deadlift'] },
  ],
  weeks: [
    { weekNumber: 1, percentage: 70, setsRange: [3, 3], repsPerSet: 6 },
    { weekNumber: 2, percentage: 80, setsRange: [3, 3], repsPerSet: 5 },
    { weekNumber: 3, percentage: 90, setsRange: [3, 3], repsPerSet: 3 },
    { weekNumber: 4, percentage: 70, setsRange: [3, 3], repsPerSet: 6 },
    { weekNumber: 5, percentage: 80, setsRange: [3, 3], repsPerSet: 5 },
    { weekNumber: 6, percentage: 90, setsRange: [3, 3], repsPerSet: 3 },
    { weekNumber: 7, percentage: 75, setsRange: [3, 3], repsPerSet: 6 },
    { weekNumber: 8, percentage: 85, setsRange: [3, 3], repsPerSet: 5 },
    { weekNumber: 9, percentage: 95, setsRange: [3, 3], repsPerSet: 1 },
    { weekNumber: 10, percentage: 75, setsRange: [3, 3], repsPerSet: 6 },
    { weekNumber: 11, percentage: 85, setsRange: [3, 3], repsPerSet: 5 },
    { weekNumber: 12, percentage: 95, setsRange: [3, 3], repsPerSet: 1 },
  ],
  sessionDefs: [
    { sessionNumber: 1, type: 'strength', liftSource: 'cluster' },
    { sessionNumber: 2, type: 'strength', liftSource: 'cluster' },
    { sessionNumber: 3, type: 'strength', liftSource: 'cluster' },
  ],
};

export const ALL_TEMPLATES: TemplateDef[] = [
  OPERATOR,
  ZULU,
  FIGHTER,
  GLADIATOR,
  MASS_PROTOCOL,
  MASS_STRENGTH,
  GREY_MAN,
];

export function getTemplate(id: TemplateId): TemplateDef | undefined {
  return ALL_TEMPLATES.find((t) => t.id === id);
}

export function getTemplatesForDays(days: number): TemplateDef[] {
  if (days === 2) return [FIGHTER];
  if (days === 3) return [OPERATOR, GLADIATOR, MASS_PROTOCOL, GREY_MAN];
  if (days === 4) return [ZULU];
  return ALL_TEMPLATES;
}
