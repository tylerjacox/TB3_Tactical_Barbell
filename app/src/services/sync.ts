import { signal } from '@preact/signals';
import { getAccessToken, refreshAccessToken, authState } from './auth';

// --- Sync State (reactive via Preact Signals) ---

const LAST_SYNCED_KEY = 'tb3_last_synced_at';
const API_URL = import.meta.env.VITE_API_URL;
const SYNC_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes

export const syncState = signal<{
  isSyncing: boolean;
  lastSyncedAt: string | null;
  error: string | null;
}>({
  isSyncing: false,
  lastSyncedAt: localStorage.getItem(LAST_SYNCED_KEY),
  error: null,
});

// --- Dependency Injection (provided by storage service) ---

type GetLocalChanges = (since: string | null) => Promise<{
  profile: Record<string, unknown> | null;
  activeProgram: Record<string, unknown> | null;
  newSessions: Array<Record<string, unknown>>;
  newMaxTests: Array<Record<string, unknown>>;
}>;

type ApplyRemoteChanges = (pull: {
  profile: Record<string, unknown> | null;
  activeProgram: Record<string, unknown> | null;
  newSessions: Array<Record<string, unknown>>;
  newMaxTests: Array<Record<string, unknown>>;
}) => Promise<void>;

type IsWorkoutActive = () => boolean;

let getLocalChanges: GetLocalChanges;
let applyRemoteChanges: ApplyRemoteChanges;
let isWorkoutActive: IsWorkoutActive;

/**
 * Initialize sync with storage service callbacks.
 * Must be called before performSync().
 */
export function initSync(deps: {
  getLocalChanges: GetLocalChanges;
  applyRemoteChanges: ApplyRemoteChanges;
  isWorkoutActive: IsWorkoutActive;
}): void {
  getLocalChanges = deps.getLocalChanges;
  applyRemoteChanges = deps.applyRemoteChanges;
  isWorkoutActive = deps.isWorkoutActive;
}

// --- Core Sync ---

/**
 * Perform a full sync cycle: push local changes, pull remote changes.
 * Skips if not authenticated, offline, already syncing, or mid-workout.
 */
export async function performSync(): Promise<void> {
  if (!authState.value.isAuthenticated) return;
  if (!navigator.onLine) return;
  if (syncState.value.isSyncing) return;
  if (isWorkoutActive?.()) return;

  let token = getAccessToken();
  if (!token) {
    token = await refreshAccessToken();
    if (!token) return;
  }

  syncState.value = { ...syncState.value, isSyncing: true, error: null };

  try {
    // Always push local changes since last sync
    const lastSyncedAt = syncState.value.lastSyncedAt;
    const push = await getLocalChanges(lastSyncedAt);

    // Always request full pull (null) — client deduplicates by ID.
    let response = await fetch(`${API_URL}/sync`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ lastSyncedAt: null, push }),
    });

    // On 401, try refreshing token and retry once
    if (response.status === 401) {
      token = await refreshAccessToken();
      if (!token) {
        throw new Error('Session expired. Please sign out and sign in again.');
      }
      response = await fetch(`${API_URL}/sync`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ lastSyncedAt: null, push }),
      });
    }

    if (!response.ok) {
      throw new Error(`Sync failed (${response.status})`);
    }

    const data = await response.json();

    // Apply remote changes to local IndexedDB
    await applyRemoteChanges(data.pull);

    // Update last synced timestamp
    localStorage.setItem(LAST_SYNCED_KEY, data.serverTime);
    syncState.value = {
      isSyncing: false,
      lastSyncedAt: data.serverTime,
      error: null,
    };
  } catch (err: any) {
    syncState.value = {
      ...syncState.value,
      isSyncing: false,
      error: err.message || 'Sync failed',
    };
  }
}

// --- Periodic Sync ---

let syncInterval: ReturnType<typeof setInterval> | null = null;

export function startPeriodicSync(): void {
  stopPeriodicSync();

  // Sync every 5 minutes
  syncInterval = setInterval(() => performSync(), SYNC_INTERVAL_MS);

  // Sync when app is foregrounded
  document.addEventListener('visibilitychange', onVisibilityChange);

  // Sync when coming back online
  window.addEventListener('online', onOnline);
}

export function stopPeriodicSync(): void {
  if (syncInterval) {
    clearInterval(syncInterval);
    syncInterval = null;
  }
  document.removeEventListener('visibilitychange', onVisibilityChange);
  window.removeEventListener('online', onOnline);
}

function onVisibilityChange(): void {
  if (document.visibilityState === 'visible') {
    performSync();
  }
}

function onOnline(): void {
  performSync();
}
