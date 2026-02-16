// IndexedDB storage via idb-keyval custom store
import { createStore, get, set, del } from 'idb-keyval';
import type { AppData, OneRepMaxTest, SessionLog } from '../types';
import { createDefaultAppData, CURRENT_SCHEMA_VERSION } from '../types';
import { migrateData } from './migrations';
import { validateAppData } from './validation';

const store = createStore('tb3', 'app');

const DATA_KEY = 'data';
const BACKUP_KEY = 'data_backup';

export async function loadAppData(): Promise<AppData> {
  let raw = await get<AppData>(DATA_KEY, store);

  if (!raw) {
    // Check if backup exists from failed migration
    const backup = await get<AppData>(BACKUP_KEY, store);
    if (backup) {
      raw = backup;
    } else {
      const defaults = createDefaultAppData();
      await set(DATA_KEY, defaults, store);
      return defaults;
    }
  }

  // Run migrations if needed
  if (raw.schemaVersion < CURRENT_SCHEMA_VERSION) {
    // Backup before migration
    await set(BACKUP_KEY, structuredClone(raw), store);
    try {
      raw = migrateData(raw, CURRENT_SCHEMA_VERSION);
      await set(DATA_KEY, raw, store);
      await del(BACKUP_KEY, store);
    } catch (e) {
      console.error('Migration failed:', e);
      // Data stays at old version; backup preserved
      throw e;
    }
  }

  // Validate
  const result = validateAppData(raw);
  if (result.severity === 'fatal') {
    console.error('Data validation fatal:', result.errors);
    throw new Error('Data is corrupted: ' + result.errors.join(', '));
  }

  return raw;
}

export async function saveAppData(data: AppData): Promise<void> {
  await set(DATA_KEY, data, store);
}

export async function clearAllData(): Promise<void> {
  await del(DATA_KEY, store);
  await del(BACKUP_KEY, store);
  localStorage.removeItem('tb3_auth_tokens');
  localStorage.removeItem('tb3_last_auth');
  localStorage.removeItem('tb3_last_synced_at');
}

// --- Sync Integration ---

export async function getLocalChanges(since: string | null): Promise<{
  profile: Record<string, unknown> | null;
  activeProgram: Record<string, unknown> | null;
  newSessions: Array<Record<string, unknown>>;
  newMaxTests: Array<Record<string, unknown>>;
}> {
  const data = await get<AppData>(DATA_KEY, store);
  if (!data) {
    return { profile: null, activeProgram: null, newSessions: [], newMaxTests: [] };
  }

  const sinceDate = since ? new Date(since).getTime() : 0;

  const profileModified = new Date(data.profile.lastModified).getTime();
  const profile = profileModified > sinceDate ? (data.profile as unknown as Record<string, unknown>) : null;

  const programModified = data.activeProgram
    ? new Date(data.activeProgram.lastModified).getTime()
    : 0;
  const activeProgram =
    data.activeProgram && programModified > sinceDate
      ? (data.activeProgram as unknown as Record<string, unknown>)
      : null;

  const newSessions = data.sessionHistory
    .filter((s) => new Date(s.lastModified).getTime() > sinceDate)
    .map((s) => s as unknown as Record<string, unknown>);

  const newMaxTests = data.maxTestHistory
    .filter((t) => new Date(t.lastModified).getTime() > sinceDate)
    .map((t) => t as unknown as Record<string, unknown>);

  return { profile, activeProgram, newSessions, newMaxTests };
}

export async function applyRemoteChanges(pull: {
  profile: Record<string, unknown> | null;
  activeProgram: Record<string, unknown> | null;
  newSessions: Array<Record<string, unknown>>;
  newMaxTests: Array<Record<string, unknown>>;
}): Promise<void> {
  const data = await get<AppData>(DATA_KEY, store) ?? createDefaultAppData();

  // Profile: last-write-wins
  if (pull.profile) {
    const remote = pull.profile as unknown as typeof data.profile;
    if (new Date(remote.lastModified).getTime() > new Date(data.profile.lastModified).getTime()) {
      data.profile = remote;
    }
  }

  // Active program: last-write-wins
  if (pull.activeProgram) {
    const remote = pull.activeProgram as unknown as typeof data.activeProgram;
    if (
      !data.activeProgram ||
      (remote && new Date(remote.lastModified).getTime() > new Date(data.activeProgram.lastModified).getTime())
    ) {
      data.activeProgram = remote;
    }
  }

  // Sessions: union by ID
  if (pull.newSessions?.length) {
    const existingIds = new Set(data.sessionHistory.map((s) => s.id));
    for (const s of pull.newSessions) {
      const session = s as unknown as SessionLog;
      if (!existingIds.has(session.id)) {
        data.sessionHistory.push(session);
      }
    }
  }

  // Max tests: union by ID
  if (pull.newMaxTests?.length) {
    const existingIds = new Set(data.maxTestHistory.map((t) => t.id));
    for (const t of pull.newMaxTests) {
      const test = t as unknown as OneRepMaxTest;
      if (!existingIds.has(test.id)) {
        data.maxTestHistory.push(test);
      }
    }
  }

  await set(DATA_KEY, data, store);
}
