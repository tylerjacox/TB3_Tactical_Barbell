import { useEffect } from 'preact/hooks';
import {
  authState,
  initAuth,
  signIn,
  signOut,
  forgotPassword,
  confirmPassword,
  completeNewPassword,
} from '../services/auth';

/**
 * Auth hook — initializes auth on mount, provides reactive auth state
 * and action methods.
 *
 * Usage:
 *   const { isAuthenticated, isLoading, user, error, signIn, signOut } = useAuth();
 */
export function useAuth() {
  useEffect(() => {
    initAuth();
  }, []);

  return {
    isAuthenticated: authState.value.isAuthenticated,
    isLoading: authState.value.isLoading,
    user: authState.value.user,
    error: authState.value.error,
    signIn,
    signOut,
    forgotPassword,
    confirmPassword,
    completeNewPassword,
  };
}
