// AppData validation + import validation (PRD 7.5, 7.6)
import type { AppData } from '../types';
import { LIFT_NAMES, TEMPLATE_IDS, CURRENT_SCHEMA_VERSION } from '../types';

export interface ValidationResult {
  severity: 'ok' | 'warning' | 'recoverable' | 'fatal';
  errors: string[];
}

const KNOWN_LIFTS = new Set<string>(LIFT_NAMES);
const KNOWN_TEMPLATES = new Set<string>(TEMPLATE_IDS);

export function validateAppData(data: AppData): ValidationResult {
  const errors: string[] = [];
  let severity: ValidationResult['severity'] = 'ok';

  if (!data || typeof data !== 'object') {
    return { severity: 'fatal', errors: ['Data is not an object'] };
  }

  if (!data.profile) {
    return { severity: 'fatal', errors: ['Missing profile'] };
  }

  // Validate activeProgram references
  if (data.activeProgram) {
    if (!KNOWN_TEMPLATES.has(data.activeProgram.templateId)) {
      errors.push(`Unknown template: ${data.activeProgram.templateId}`);
      severity = 'recoverable';
    }
  }

  // Validate lift names in max test history
  for (const test of data.maxTestHistory || []) {
    if (!KNOWN_LIFTS.has(test.liftName)) {
      errors.push(`Unknown lift in maxTestHistory: ${test.liftName}`);
      severity = 'warning';
    }
    if (test.weight < 1 || test.weight > 1500) {
      errors.push(`Weight out of range: ${test.weight}`);
      severity = 'warning';
    }
    if (test.reps < 1 || test.reps > 15) {
      errors.push(`Reps out of range: ${test.reps}`);
      severity = 'warning';
    }
  }

  // Validate session history IDs are unique
  const sessionIds = new Set<string>();
  for (const s of data.sessionHistory || []) {
    if (sessionIds.has(s.id)) {
      errors.push(`Duplicate session ID: ${s.id}`);
      severity = 'warning';
    }
    sessionIds.add(s.id);
  }

  const testIds = new Set<string>();
  for (const t of data.maxTestHistory || []) {
    if (testIds.has(t.id)) {
      errors.push(`Duplicate max test ID: ${t.id}`);
      severity = 'warning';
    }
    testIds.add(t.id);
  }

  return { severity, errors };
}

// --- Import Validation (PRD 7.5 — 12-step sequential checklist) ---

export function validateImportData(
  raw: string,
): { valid: true; data: any } | { valid: false; error: string } {
  // Step 1: File size
  if (raw.length > 1_000_000) {
    return { valid: false, error: 'File too large. Maximum size is 1MB.' };
  }

  // Step 2: Valid JSON
  let parsed: any;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { valid: false, error: 'Invalid file format. Could not parse JSON.' };
  }

  // Step 3: Sentinel check
  if (parsed.tb3_export !== true) {
    return { valid: false, error: 'This file does not appear to be a TB3 backup.' };
  }

  // Step 4: Schema version exists
  if (typeof parsed.schemaVersion !== 'number') {
    return { valid: false, error: 'Unrecognized backup version.' };
  }

  // Step 5: Schema version not newer
  if (parsed.schemaVersion > CURRENT_SCHEMA_VERSION) {
    return {
      valid: false,
      error: 'This backup is from a newer version of TB3. Please update the app first.',
    };
  }

  // Step 6: Prototype pollution defense
  if (hasPrototypePollution(parsed)) {
    return { valid: false, error: 'Invalid file: contains unsafe keys.' };
  }

  // Step 7: Migrations handled by caller after validation

  // Step 8: Required fields
  if (!parsed.profile || typeof parsed.profile !== 'object') {
    return { valid: false, error: 'Missing or invalid profile data.' };
  }
  if (!Array.isArray(parsed.sessionHistory)) {
    return { valid: false, error: 'Missing or invalid session history.' };
  }
  if (!Array.isArray(parsed.maxTestHistory)) {
    return { valid: false, error: 'Missing or invalid max test history.' };
  }

  // Step 9: Numeric range validation
  for (const test of parsed.maxTestHistory) {
    if (typeof test.weight !== 'number' || test.weight < 1 || test.weight > 1500) {
      return { valid: false, error: `Weight out of range: ${test.weight}. Must be 1-1500.` };
    }
    if (typeof test.reps !== 'number' || test.reps < 1 || test.reps > 15) {
      return { valid: false, error: `Reps out of range: ${test.reps}. Must be 1-15.` };
    }
  }

  // Step 10: String length validation
  for (const session of parsed.sessionHistory) {
    if (session.notes && typeof session.notes === 'string' && session.notes.length > 500) {
      return { valid: false, error: 'Session notes exceed 500 character limit.' };
    }
  }

  // Step 11: ID uniqueness
  const sessionIds = new Set<string>();
  for (const s of parsed.sessionHistory) {
    if (sessionIds.has(s.id)) {
      return { valid: false, error: `Duplicate session ID found: ${s.id}` };
    }
    sessionIds.add(s.id);
  }
  const testIds = new Set<string>();
  for (const t of parsed.maxTestHistory) {
    if (testIds.has(t.id)) {
      return { valid: false, error: `Duplicate max test ID found: ${t.id}` };
    }
    testIds.add(t.id);
  }

  // Step 12: Confirmation handled by UI
  return { valid: true, data: parsed };
}

function hasPrototypePollution(obj: any): boolean {
  if (obj === null || typeof obj !== 'object') return false;
  for (const key of Object.keys(obj)) {
    if (key === '__proto__' || key === 'constructor' || key === 'prototype') {
      return true;
    }
    if (typeof obj[key] === 'object' && obj[key] !== null) {
      if (hasPrototypePollution(obj[key])) return true;
    }
  }
  return false;
}
