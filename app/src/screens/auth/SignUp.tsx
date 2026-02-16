import { useState } from 'preact/hooks';
import { authState, signUp } from '../../services/auth';

/**
 * Sign Up screen — create a new account with email + password.
 * On success, navigates to ConfirmEmail for verification code entry.
 */
export function SignUp({
  onSignUpSuccess,
  onBackToLogin,
}: {
  onSignUpSuccess: (email: string) => void;
  onBackToLogin: () => void;
}) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPw, setConfirmPw] = useState('');
  const [localError, setLocalError] = useState('');

  const { isLoading, error } = authState.value;

  async function handleSignUp(e: Event) {
    e.preventDefault();
    setLocalError('');

    if (!email.trim()) {
      setLocalError('Please enter your email.');
      return;
    }

    if (password.length < 8) {
      setLocalError('Password must be at least 8 characters.');
      return;
    }

    if (password !== confirmPw) {
      setLocalError('Passwords do not match.');
      return;
    }

    try {
      await signUp(email.trim(), password);
      onSignUpSuccess(email.trim());
    } catch {
      // Error is set in authState by the service
    }
  }

  return (
    <div class="auth-screen">
      <div class="auth-card">
        <h1 class="auth-title">Create Account</h1>
        <p class="auth-subtitle">Sign up to back up and sync your training data.</p>

        <form onSubmit={handleSignUp}>
          <div class="auth-field">
            <label for="signup-email">Email</label>
            <input
              id="signup-email"
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
            <label for="signup-password">Password</label>
            <input
              id="signup-password"
              type="password"
              value={password}
              onInput={(e) => setPassword((e.target as HTMLInputElement).value)}
              placeholder="At least 8 characters"
              autocomplete="new-password"
              required
              disabled={isLoading}
            />
          </div>

          <div class="auth-field">
            <label for="signup-confirm">Confirm Password</label>
            <input
              id="signup-confirm"
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
            {isLoading ? 'Creating account...' : 'Create Account'}
          </button>
        </form>

        <button
          type="button"
          class="auth-link"
          onClick={onBackToLogin}
          disabled={isLoading}
        >
          Already have an account? Sign in
        </button>
      </div>
    </div>
  );
}
