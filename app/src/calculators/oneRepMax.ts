// 1RM Calculator — Epley Formula (PRD 5.1)

export function calculateOneRepMax(weight: number, reps: number): number {
  if (reps <= 0 || weight <= 0) return 0;
  if (reps === 1) return weight;
  return weight * (1 + reps / 30);
}

export function calculateTrainingMax(oneRepMax: number): number {
  return oneRepMax * 0.9;
}

export function roundWeight(weight: number, increment: 2.5 | 5): number {
  return Math.round(weight / increment) * increment;
}

export function calculatePercentageWeight(
  workingMax: number,
  percentage: number,
  roundingIncrement: 2.5 | 5,
): number {
  return roundWeight(workingMax * (percentage / 100), roundingIncrement);
}

export interface PercentageRow {
  percentage: number;
  weight: number;
}

export function calculatePercentageTable(
  workingMax: number,
  roundingIncrement: 2.5 | 5,
): PercentageRow[] {
  const percentages = [65, 70, 75, 80, 85, 90, 95, 100];
  return percentages.map((p) => ({
    percentage: p,
    weight: calculatePercentageWeight(workingMax, p, roundingIncrement),
  }));
}
