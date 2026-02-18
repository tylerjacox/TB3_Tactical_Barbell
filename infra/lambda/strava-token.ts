// TB3 — Strava Token Exchange Proxy
// Proxies OAuth token requests to Strava, injecting the client_secret from Secrets Manager.
// This keeps the client_secret out of the iOS app binary.

import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from '@aws-sdk/client-secrets-manager';

const secretsClient = new SecretsManagerClient({});
const SECRET_NAME = process.env.STRAVA_SECRET_NAME!;
const STRAVA_TOKEN_URL = 'https://www.strava.com/api/v3/oauth/token';

// Cache the secret to avoid repeated lookups
let cachedSecret: { clientId: string; clientSecret: string } | null = null;

async function getStravaCredentials() {
  if (cachedSecret) return cachedSecret;

  const response = await secretsClient.send(
    new GetSecretValueCommand({ SecretId: SECRET_NAME })
  );

  const secret = JSON.parse(response.SecretString!);
  cachedSecret = {
    clientId: secret.clientId,
    clientSecret: secret.clientSecret,
  };
  return cachedSecret;
}

function respond(statusCode: number, body: unknown) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
    body: JSON.stringify(body),
  };
}

export const handler = async (event: {
  body?: string;
}): Promise<{ statusCode: number; headers: Record<string, string>; body: string }> => {
  try {
    if (!event.body) {
      return respond(400, { error: 'Missing request body' });
    }

    const request = JSON.parse(event.body);
    const { grant_type } = request;

    if (!grant_type || !['authorization_code', 'refresh_token'].includes(grant_type)) {
      return respond(400, { error: 'Invalid grant_type' });
    }

    const credentials = await getStravaCredentials();

    // Build the request to Strava
    const stravaBody: Record<string, string> = {
      client_id: credentials.clientId,
      client_secret: credentials.clientSecret,
      grant_type,
    };

    if (grant_type === 'authorization_code') {
      if (!request.code) {
        return respond(400, { error: 'Missing authorization code' });
      }
      stravaBody.code = request.code;
      if (request.code_verifier) {
        stravaBody.code_verifier = request.code_verifier;
      }
    } else if (grant_type === 'refresh_token') {
      if (!request.refresh_token) {
        return respond(400, { error: 'Missing refresh_token' });
      }
      stravaBody.refresh_token = request.refresh_token;
    }

    // Forward to Strava (requires form-urlencoded, not JSON)
    const stravaResponse = await fetch(STRAVA_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams(stravaBody).toString(),
    });

    const stravaData = await stravaResponse.json();

    if (!stravaResponse.ok) {
      return respond(stravaResponse.status, stravaData);
    }

    return respond(200, stravaData);
  } catch (error) {
    console.error('Strava token proxy error:', error);
    return respond(500, { error: 'Internal server error' });
  }
};
