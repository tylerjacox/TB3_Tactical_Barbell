import { useState } from 'preact/hooks';
import { forgotPassword, confirmPassword } from '../../services/auth';

/**
 * Forgot Password screen — two phases:
 * 1. Enter email to receive verification code
 * 2. Enter code + new password to reset
 */
export function ForgotPassword({ onBack }: { onBack: () => void }) {
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPw, setConfirmPw] = useState('');
  const [phase, setPhase] = useState<'email' | 'code'>('email');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  async function handleSendCode(e: Event) {
    e.preventDefault();
    setError('');

    if (!email.trim()) {
      setError('Please enter your email address.');
      return;
    }

    setIsLoading(true);
    try {
      await forgotPassword(email.trim());
      setPhase('code');
      setSuccess('Verification code sent to your email.');
    } catch (err: any) {
      setError(err.message || 'Failed to send verification code.');
    } finally {
      setIsLoading(false);
    }
  }

  async function handleResetPassword(e: Event) {
    e.preventDefault();
    setError('');

    if (!code.trim()) {
      setError('Please enter the verification code.');
      return;
    }

    if (newPassword.length < 8) {
      setError('Password must be at least 8 characters.');
      return;
    }

    if (newPassword !== confirmPw) {
      setError('Passwords do not match.');
      return;
    }

    setIsLoading(true);
    try {
      await confirmPassword(email.trim(), code.trim(), newPassword);
      setSuccess('Password reset successfully. You can now sign in.');
      setPhase('email');
      // Clear form
      setEmail('');
      setCode('');
      setNewPassword('');
      setConfirmPw('');
      // Navigate back to login after brief delay
      setTimeout(onBack, 2000);
    } catch (err: any) {
      setError(err.message || 'Failed to reset password.');
    } finally {
      setIsLoading(false);
    }
  }

  if (phase === 'code') {
    return (
      <div class="auth-screen">
        <div class="auth-card">
          <h1 class="auth-title">Reset Password</h1>
          <p class="auth-subtitle">
            Enter the verification code sent to {email} and choose a new password.
          </p>

          {success && <p class="auth-success" role="status">{success}</p>}

          <form onSubmit={handleResetPassword}>
            <div class="auth-field">
              <label for="code">Verification Code</label>
              <input
                id="code"
                type="text"
                inputMode="numeric"
                value={code}
                onInput={(e) => setCode((e.target as HTMLInputElement).value)}
                placeholder="Enter 6-digit code"
                autocomplete="one-time-code"
                required
                disabled={isLoading}
              />
            </div>

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

            {error && <p class="auth-error" role="alert">{error}</p>}

            <button type="submit" class="auth-button" disabled={isLoading}>
              {isLoading ? 'Resetting...' : 'Reset Password'}
            </button>
          </form>

          <button type="button" class="auth-link" onClick={() => setPhase('email')}>
            Didn't receive a code? Send again
          </button>

          <button type="button" class="auth-link" onClick={onBack}>
            Back to Sign In
          </button>
        </div>
      </div>
    );
  }

  return (
    <div class="auth-screen">
      <div class="auth-card">
        <h1 class="auth-title">Forgot Password</h1>
        <p class="auth-subtitle">
          Enter your email and we'll send you a verification code.
        </p>

        {success && <p class="auth-success" role="status">{success}</p>}

        <form onSubmit={handleSendCode}>
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

          {error && <p class="auth-error" role="alert">{error}</p>}

          <button type="submit" class="auth-button" disabled={isLoading}>
            {isLoading ? 'Sending...' : 'Send Verification Code'}
          </button>
        </form>

        <button type="button" class="auth-link" onClick={onBack}>
          Back to Sign In
        </button>
      </div>
    </div>
  );
}
