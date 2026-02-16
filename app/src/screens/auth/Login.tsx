import { useState } from 'preact/hooks';
import { authState, signIn, completeNewPassword } from '../../services/auth';

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
