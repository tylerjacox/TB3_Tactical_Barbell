import { useEffect } from 'preact/hooks';
import {
  syncState,
  performSync,
  startPeriodicSync,
  stopPeriodicSync,
} from '../services/sync';
import { authState } from '../services/auth';

/**
 * Sync hook — starts/stops periodic sync based on auth state.
 * Triggers initial sync on mount when authenticated.
 *
 * Usage:
 *   const { isSyncing, lastSyncedAt, error, syncNow } = useSync();
 */
export function useSync() {
  useEffect(() => {
    if (authState.value.isAuthenticated) {
      performSync();
      startPeriodicSync();
      return () => stopPeriodicSync();
    }
  }, [authState.value.isAuthenticated]);

  return {
    isSyncing: syncState.value.isSyncing,
    lastSyncedAt: syncState.value.lastSyncedAt,
    error: syncState.value.error,
    syncNow: performSync,
  };
}
