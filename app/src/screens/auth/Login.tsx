import { useState } from 'preact/hooks';
import { authState, signIn, completeNewPassword, signInWithGoogle } from '../../services/auth';

/**
 * Login screen — email/password sign-in.
 * Handles NEW_PASSWORD_REQUIRED challenge for admin-created accounts.
 */
export function Login({ onForgotPassword, onSignUp }: { onForgotPassword: () => void; onSignUp: () => void }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPw, setConfirmPw] = useState('');
  const [needsNewPassword, setNeedsNewPassword] = useState(false);
  const [localError, setLocalError] = useState('');

  const { isLoading, error } = authState.value;

  async function handleSignIn(e: Event) {
    e.preventDefault();
    setLocalError('');

    if (!email.trim() || !password.trim()) {
      setLocalError('Please enter your email and password.');
      return;
    }

    try {
      const result = await signIn(email.trim(), password);
      if (result === 'NEW_PASSWORD_REQUIRED') {
        setNeedsNewPassword(true);
      }
    } catch {
      // Error is set in authState by the service
    }
  }

  async function handleNewPassword(e: Event) {
    e.preventDefault();
    setLocalError('');

    if (newPassword.length < 8) {
      setLocalError('Password must be at least 8 characters.');
      return;
    }

    if (newPassword !== confirmPw) {
      setLocalError('Passwords do not match.');
      return;
    }

    try {
      await completeNewPassword(newPassword);
    } catch {
      // Error is set in authState by the service
    }
  }

  if (needsNewPassword) {
    return (
      <div class="auth-screen">
        <div class="auth-card">
          <h1 class="auth-title">Set New Password</h1>
          <p class="auth-subtitle">
            Please choose a new password to complete your account setup.
          </p>

          <form onSubmit={handleNewPassword}>
            <div class="auth-field">
              <label for="new-password">New Password</label>
              <input
                id="new-password"
                type="password"
                value={newPassword}
                onInput={(e) => setNewPassword((e.target as HTMLInputElement).value)}
                placeholder="At least 8 characters"
                autocomplete="new-password"
                required
                disabled={isLoading}
              />
            </div>

            <div class="auth-field">
              <label for="confirm-password">Confirm Password</label>
              <input
                id="confirm-password"
                type="password"
                value={confirmPw}
                onInput={(e) => setConfirmPw((e.target as HTMLInputElement).value)}
                placeholder="Re-enter password"
                autocomplete="new-password"
                required
                disabled={isLoading}
              />
            </div>

            {(localError || error) && (
              <p class="auth-error" role="alert">{localError || error}</p>
            )}

            <button type="submit" class="auth-button" disabled={isLoading}>
              {isLoading ? 'Setting password...' : 'Set Password'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div class="auth-screen">
      <div class="auth-card">
        <h1 class="auth-title">TB3</h1>
        <p class="auth-subtitle">Sign in to sync your training data.</p>

        <form onSubmit={handleSignIn}>
          <div class="auth-field">
            <label for="email">Email</label>
            <input
              id="email"
              type="email"
              value={email}
              onInput={(e) => setEmail((e.target as HTMLInputElement).value)}
              placeholder="you@example.com"
              autocomplete="email"
              required
              disabled={isLoading}
            />
          </div>

          <div class="auth-field">
            <label for="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onInput={(e) => setPassword((e.target as HTMLInputElement).value)}
              placeholder="Password"
              autocomplete="current-password"
              required
              disabled={isLoading}
            />
          </div>

          {(localError || error) && (
            <p class="auth-error" role="alert">{localError || error}</p>
          )}

          <button type="submit" class="auth-button" disabled={isLoading}>
            {isLoading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <div class="auth-divider">
          <span>or</span>
        </div>

        <button
          type="button"
          class="google-btn"
          onClick={() => signInWithGoogle()}
          disabled={isLoading}
        >
          <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
            <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/>
            <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
            <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
            <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
          </svg>
          Sign in with Google
        </button>

        <button
          type="button"
          class="auth-link"
          onClick={onForgotPassword}
          disabled={isLoading}
        >
          Forgot password?
        </button>

        <button
          type="button"
          class="auth-link"
          onClick={onSignUp}
          disabled={isLoading}
        >
          Create an account
        </button>
      </div>
    </div>
  );
}
