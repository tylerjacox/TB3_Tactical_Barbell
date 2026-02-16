import { useState } from 'preact/hooks';

/**
 * Confirm Email screen — for entering a verification code.
 * Used when Cognito requires email confirmation before allowing sign-in.
 */
export function ConfirmEmail({
  email,
  onConfirmed,
  onBack,
}: {
  email: string;
  onConfirmed: () => void;
  onBack: () => void;
}) {
  const [code, setCode] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [resent, setResent] = useState(false);

  async function handleConfirm(e: Event) {
    e.preventDefault();
    setError('');

    if (!code.trim()) {
      setError('Please enter the verification code.');
      return;
    }

    setIsLoading(true);
    try {
      const { CognitoUser } = await import('amazon-cognito-identity-js');
      const { CognitoUserPool } = await import('amazon-cognito-identity-js');

      const userPool = new CognitoUserPool({
        UserPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
        ClientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
      });

      const user = new CognitoUser({ Username: email, Pool: userPool });

      await new Promise<void>((resolve, reject) => {
        user.confirmRegistration(code.trim(), true, (err, result) => {
          if (err) reject(err);
          else resolve();
        });
      });

      onConfirmed();
    } catch (err: any) {
      setError(err.message || 'Invalid verification code. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }

  async function handleResend() {
    setError('');
    setResent(false);

    try {
      const { CognitoUser, CognitoUserPool } = await import('amazon-cognito-identity-js');

      const userPool = new CognitoUserPool({
        UserPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
        ClientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
      });

      const user = new CognitoUser({ Username: email, Pool: userPool });

      await new Promise<void>((resolve, reject) => {
        user.resendConfirmationCode((err) => {
          if (err) reject(err);
          else resolve();
        });
      });

      setResent(true);
    } catch (err: any) {
      setError(err.message || 'Failed to resend code.');
    }
  }

  return (
    <div class="auth-screen">
      <div class="auth-card">
        <h1 class="auth-title">Verify Email</h1>
        <p class="auth-subtitle">
          Enter the verification code sent to {email}.
        </p>

        {resent && (
          <p class="auth-success" role="status">
            A new code has been sent to your email.
          </p>
        )}

        <form onSubmit={handleConfirm}>
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

          {error && <p class="auth-error" role="alert">{error}</p>}

          <button type="submit" class="auth-button" disabled={isLoading}>
            {isLoading ? 'Verifying...' : 'Verify Email'}
          </button>
        </form>

        <button type="button" class="auth-link" onClick={handleResend}>
          Resend code
        </button>

        <button type="button" class="auth-link" onClick={onBack}>
          Back to Sign In
        </button>
      </div>
    </div>
  );
}
