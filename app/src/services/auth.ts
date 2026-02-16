import { signal } from '@preact/signals';

// --- Auth State (reactive via Preact Signals) ---

export const authState = signal<{
  isAuthenticated: boolean;
  isLoading: boolean;
  user: { email: string; userId: string } | null;
  error: string | null;
}>({
  isAuthenticated: false,
  isLoading: true,
  user: null,
  error: null,
});

// --- Config ---

const POOL_ID = import.meta.env.VITE_COGNITO_USER_POOL_ID;
const CLIENT_ID = import.meta.env.VITE_COGNITO_CLIENT_ID;
const COGNITO_DOMAIN = import.meta.env.VITE_COGNITO_DOMAIN;
const REDIRECT_URI = `${window.location.origin}/`;

const TOKEN_KEY = 'tb3_auth_tokens';
const LAST_AUTH_KEY = 'tb3_last_auth';
const PKCE_VERIFIER_KEY = 'tb3_pkce_verifier';
const OFFLINE_GRACE_DAYS = 7;

interface StoredTokens {
  idToken: string;
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
}

// --- Lazy-loaded Cognito SDK (~28KB gzipped) ---

let cognitoModule: typeof import('amazon-cognito-identity-js') | null = null;

async function getCognito() {
  if (!cognitoModule) {
    cognitoModule = await import('amazon-cognito-identity-js');
  }
  return cognitoModule;
}

async function getUserPool() {
  const { CognitoUserPool } = await getCognito();
  return new CognitoUserPool({ UserPoolId: POOL_ID, ClientId: CLIENT_ID });
}

// --- Token Storage ---

function storeTokens(tokens: StoredTokens): void {
  localStorage.setItem(TOKEN_KEY, JSON.stringify(tokens));
  localStorage.setItem(LAST_AUTH_KEY, new Date().toISOString());
}

function getStoredTokens(): StoredTokens | null {
  const raw = localStorage.getItem(TOKEN_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function clearTokens(): void {
  localStorage.removeItem(TOKEN_KEY);
}

function isWithinOfflineGrace(): boolean {
  const lastAuth = localStorage.getItem(LAST_AUTH_KEY);
  if (!lastAuth) return false;
  const elapsed = Date.now() - new Date(lastAuth).getTime();
  return elapsed < OFFLINE_GRACE_DAYS * 24 * 60 * 60 * 1000;
}

// --- PKCE Helpers (OAuth2 with Proof Key for Code Exchange) ---

function generateCodeVerifier(): string {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, (b) => b.toString(36).padStart(2, '0')).join('').slice(0, 43);
}

async function generateCodeChallenge(verifier: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const digest = await crypto.subtle.digest('SHA-256', data);
  const base64 = btoa(String.fromCharCode(...new Uint8Array(digest)));
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

// --- Pending new-password challenge state ---

let pendingCognitoUser: any = null;
let pendingUserAttributes: Record<string, string> = {};

// --- Public API ---

/**
 * Redirect to Google sign-in via Cognito's OAuth2 authorize endpoint.
 * Uses PKCE since this is a public client (no client secret on frontend).
 */
export async function signInWithGoogle(): Promise<void> {
  const verifier = generateCodeVerifier();
  const challenge = await generateCodeChallenge(verifier);
  sessionStorage.setItem(PKCE_VERIFIER_KEY, verifier);

  const params = new URLSearchParams({
    identity_provider: 'Google',
    response_type: 'code',
    client_id: CLIENT_ID,
    redirect_uri: REDIRECT_URI,
    scope: 'email openid profile',
    code_challenge: challenge,
    code_challenge_method: 'S256',
  });

  window.location.href = `${COGNITO_DOMAIN}/oauth2/authorize?${params.toString()}`;
}

/**
 * Handle OAuth2 callback — exchange authorization code for tokens.
 * Called on app init if URL has ?code= param.
 * Returns true if a callback was handled.
 */
async function handleOAuthCallback(): Promise<boolean> {
  const params = new URLSearchParams(window.location.search);
  const code = params.get('code');
  if (!code) return false;

  const verifier = sessionStorage.getItem(PKCE_VERIFIER_KEY);
  if (!verifier) {
    authState.value = {
      isAuthenticated: false,
      isLoading: false,
      user: null,
      error: 'Missing PKCE verifier. Please try signing in again.',
    };
    // Clean URL
    window.history.replaceState({}, '', window.location.pathname + window.location.hash);
    return true;
  }

  authState.value = { ...authState.value, isLoading: true };

  try {
    const response = await fetch(`${COGNITO_DOMAIN}/oauth2/token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: CLIENT_ID,
        redirect_uri: REDIRECT_URI,
        code,
        code_verifier: verifier,
      }).toString(),
    });

    if (!response.ok) {
      throw new Error(`Token exchange failed: ${response.status}`);
    }

    const data = await response.json();

    const tokens: StoredTokens = {
      idToken: data.id_token,
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      expiresAt: Date.now() + data.expires_in * 1000,
    };

    storeTokens(tokens);
    sessionStorage.removeItem(PKCE_VERIFIER_KEY);

    const payload = parseJwt(tokens.idToken);
    authState.value = {
      isAuthenticated: true,
      isLoading: false,
      user: { email: payload.email, userId: payload.sub },
      error: null,
    };
  } catch (err: any) {
    sessionStorage.removeItem(PKCE_VERIFIER_KEY);
    authState.value = {
      isAuthenticated: false,
      isLoading: false,
      user: null,
      error: 'Google sign-in failed. Please try again.',
    };
  }

  // Clean URL — remove ?code= query param, preserve hash
  window.history.replaceState({}, '', window.location.pathname + window.location.hash);
  return true;
}

/**
 * Initialize auth on app launch. Checks for OAuth callback first,
 * then stored tokens, attempts refresh, falls back to offline grace period.
 */
export async function initAuth(): Promise<void> {
  authState.value = { ...authState.value, isLoading: true };

  // Check for OAuth callback (?code= from Google redirect)
  if (await handleOAuthCallback()) return;

  const tokens = getStoredTokens();
  if (!tokens) {
    authState.value = { isAuthenticated: false, isLoading: false, user: null, error: null };
    return;
  }

  // Try online token refresh (OAuth2 endpoint works for all auth methods)
  if (navigator.onLine) {
    try {
      const newToken = await refreshAccessToken();
      if (newToken) return;
    } catch {
      // Fall through to offline grace check
    }
  }

  // Offline grace period — allow access with cached tokens
  if (isWithinOfflineGrace()) {
    const payload = parseJwt(tokens.idToken);
    authState.value = {
      isAuthenticated: true,
      isLoading: false,
      user: { email: payload.email, userId: payload.sub },
      error: null,
    };
    return;
  }

  // Tokens expired and outside grace period
  clearTokens();
  authState.value = { isAuthenticated: false, isLoading: false, user: null, error: null };
}

/**
 * Sign in with email + password. Returns 'SUCCESS' or 'NEW_PASSWORD_REQUIRED'.
 * If NEW_PASSWORD_REQUIRED, call completeNewPassword() with the user's chosen password.
 */
export async function signIn(email: string, password: string): Promise<'SUCCESS' | 'NEW_PASSWORD_REQUIRED'> {
  authState.value = { ...authState.value, isLoading: true, error: null };

  try {
    const { CognitoUser, AuthenticationDetails } = await getCognito();
    const userPool = await getUserPool();
    const user = new CognitoUser({ Username: email, Pool: userPool });
    const authDetails = new AuthenticationDetails({ Username: email, Password: password });

    const result = await new Promise<{ type: 'SUCCESS'; session: any } | { type: 'NEW_PASSWORD_REQUIRED' }>(
      (resolve, reject) => {
        user.authenticateUser(authDetails, {
          onSuccess: (session) => resolve({ type: 'SUCCESS', session }),
          onFailure: reject,
          newPasswordRequired: (userAttributes) => {
            // Store for completeNewPassword()
            pendingCognitoUser = user;
            pendingUserAttributes = userAttributes;
            resolve({ type: 'NEW_PASSWORD_REQUIRED' });
          },
        });
      },
    );

    if (result.type === 'NEW_PASSWORD_REQUIRED') {
      authState.value = { ...authState.value, isLoading: false };
      return 'NEW_PASSWORD_REQUIRED';
    }

    setSessionFromResult(result.session);
    return 'SUCCESS';
  } catch (err: any) {
    authState.value = {
      ...authState.value,
      isLoading: false,
      error: mapCognitoError(err),
    };
    throw err;
  }
}

/**
 * Complete the NEW_PASSWORD_REQUIRED challenge after first admin-created login.
 */
export async function completeNewPassword(newPassword: string): Promise<void> {
  if (!pendingCognitoUser) {
    throw new Error('No pending password challenge');
  }

  authState.value = { ...authState.value, isLoading: true, error: null };

  try {
    const result = await new Promise<any>((resolve, reject) => {
      pendingCognitoUser.completeNewPasswordChallenge(newPassword, {}, {
        onSuccess: resolve,
        onFailure: reject,
      });
    });

    pendingCognitoUser = null;
    pendingUserAttributes = {};
    setSessionFromResult(result);
  } catch (err: any) {
    authState.value = {
      ...authState.value,
      isLoading: false,
      error: mapCognitoError(err),
    };
    throw err;
  }
}

/**
 * Sign out — clears tokens locally. Keeps local IndexedDB data.
 */
export async function signOut(): Promise<void> {
  // Clear local state immediately so the UI updates
  clearTokens();
  authState.value = { isAuthenticated: false, isLoading: false, user: null, error: null };

  // Best-effort Cognito cleanup (non-blocking)
  try {
    const userPool = await getUserPool();
    const user = userPool.getCurrentUser();
    if (user) user.signOut();
  } catch {
    // Ignore — local tokens already cleared
  }
}

/**
 * Sign up a new user with email + password. Cognito will send a verification code.
 * After sign-up, user must confirm their email via ConfirmEmail screen.
 */
export async function signUp(email: string, password: string): Promise<void> {
  authState.value = { ...authState.value, isLoading: true, error: null };

  try {
    const { CognitoUserAttribute } = await getCognito();
    const userPool = await getUserPool();

    const attributes = [
      new CognitoUserAttribute({ Name: 'email', Value: email }),
    ];

    await new Promise<void>((resolve, reject) => {
      userPool.signUp(email, password, attributes, [], (err, result) => {
        if (err) reject(err);
        else resolve();
      });
    });

    authState.value = { ...authState.value, isLoading: false };
  } catch (err: any) {
    authState.value = {
      ...authState.value,
      isLoading: false,
      error: mapCognitoError(err),
    };
    throw err;
  }
}

/**
 * Initiate forgot password flow — sends verification code to email.
 */
export async function forgotPassword(email: string): Promise<void> {
  const { CognitoUser } = await getCognito();
  const userPool = await getUserPool();
  const user = new CognitoUser({ Username: email, Pool: userPool });

  return new Promise((resolve, reject) => {
    user.forgotPassword({
      onSuccess: () => resolve(),
      onFailure: (err) => reject(err),
    });
  });
}

/**
 * Confirm forgot password — enter verification code + new password.
 */
export async function confirmPassword(
  email: string,
  code: string,
  newPassword: string,
): Promise<void> {
  const { CognitoUser } = await getCognito();
  const userPool = await getUserPool();
  const user = new CognitoUser({ Username: email, Pool: userPool });

  return new Promise((resolve, reject) => {
    user.confirmPassword(code, newPassword, {
      onSuccess: () => resolve(),
      onFailure: (err) => reject(err),
    });
  });
}

/**
 * Get current access token for API calls. Returns null if expired.
 */
export function getAccessToken(): string | null {
  const tokens = getStoredTokens();
  if (!tokens) return null;
  if (Date.now() > tokens.expiresAt) return null;
  return tokens.accessToken;
}

/**
 * Get current ID token (contains user claims).
 */
export function getIdToken(): string | null {
  const tokens = getStoredTokens();
  return tokens?.idToken ?? null;
}

/**
 * Refresh access/id tokens using the refresh token via Cognito OAuth2 endpoint.
 * Works for both SDK-authenticated and OAuth-authenticated users.
 * Returns the new access token, or null if refresh failed.
 */
export async function refreshAccessToken(): Promise<string | null> {
  const tokens = getStoredTokens();
  if (!tokens?.refreshToken) return null;

  try {
    const response = await fetch(`${COGNITO_DOMAIN}/oauth2/token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        client_id: CLIENT_ID,
        refresh_token: tokens.refreshToken,
      }).toString(),
    });

    if (!response.ok) return null;

    const data = await response.json();
    const newTokens: StoredTokens = {
      idToken: data.id_token,
      accessToken: data.access_token,
      refreshToken: tokens.refreshToken, // refresh token doesn't rotate
      expiresAt: Date.now() + data.expires_in * 1000,
    };

    storeTokens(newTokens);

    const payload = parseJwt(newTokens.idToken);
    authState.value = {
      isAuthenticated: true,
      isLoading: false,
      user: { email: payload.email, userId: payload.sub },
      error: null,
    };

    return newTokens.accessToken;
  } catch {
    return null;
  }
}

// --- Internal Helpers ---

function setSessionFromResult(session: any): void {
  const tokens: StoredTokens = {
    idToken: session.getIdToken().getJwtToken(),
    accessToken: session.getAccessToken().getJwtToken(),
    refreshToken: session.getRefreshToken().getToken(),
    expiresAt: session.getAccessToken().getExpiration() * 1000,
  };

  storeTokens(tokens);
  const payload = parseJwt(tokens.idToken);
  authState.value = {
    isAuthenticated: true,
    isLoading: false,
    user: { email: payload.email, userId: payload.sub },
    error: null,
  };
}

async function refreshSession(): Promise<boolean> {
  const tokens = getStoredTokens();
  if (!tokens?.refreshToken) return false;

  try {
    const { CognitoRefreshToken } = await getCognito();
    const userPool = await getUserPool();
    const user = userPool.getCurrentUser();
    if (!user) return false;

    const refreshToken = new CognitoRefreshToken({ RefreshToken: tokens.refreshToken });

    const session = await new Promise<any>((resolve, reject) => {
      user.refreshSession(refreshToken, (err: any, result: any) => {
        if (err) reject(err);
        else resolve(result);
      });
    });

    const newTokens: StoredTokens = {
      idToken: session.getIdToken().getJwtToken(),
      accessToken: session.getAccessToken().getJwtToken(),
      refreshToken: tokens.refreshToken, // Refresh token doesn't rotate
      expiresAt: session.getAccessToken().getExpiration() * 1000,
    };

    storeTokens(newTokens);
    const payload = parseJwt(newTokens.idToken);
    authState.value = {
      isAuthenticated: true,
      isLoading: false,
      user: { email: payload.email, userId: payload.sub },
      error: null,
    };
    return true;
  } catch {
    return false;
  }
}

function parseJwt(token: string): any {
  const base64Url = token.split('.')[1];
  const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
  return JSON.parse(atob(base64));
}

function mapCognitoError(err: any): string {
  switch (err.code || err.name) {
    case 'NotAuthorizedException':
    case 'UserNotFoundException':
      return 'Incorrect email or password.';
    case 'UserNotConfirmedException':
      return 'Please verify your email before signing in.';
    case 'PasswordResetRequiredException':
      return 'You need to reset your password.';
    case 'InvalidPasswordException':
      return 'Password must be at least 8 characters with uppercase, lowercase, and numbers.';
    case 'UsernameExistsException':
      return 'An account with this email already exists.';
    case 'InvalidParameterException':
      return 'Please check your input and try again.';
    case 'LimitExceededException':
      return 'Too many attempts. Please try again later.';
    case 'NetworkError':
      return 'No internet connection. Please try again.';
    default:
      return err.message || 'An error occurred. Please try again.';
  }
}
