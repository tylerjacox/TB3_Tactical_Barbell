// TB3 — Spotify Token Exchange Proxy
// Proxies OAuth token requests to Spotify, injecting the client_secret from Secrets Manager.
// Supports PKCE authorization_code and refresh_token grants.

import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from '@aws-sdk/client-secrets-manager';

const secretsClient = new SecretsManagerClient({});
const SECRET_NAME = process.env.SPOTIFY_SECRET_NAME!;
const SPOTIFY_TOKEN_URL = 'https://accounts.spotify.com/api/token';

let cachedSecret: { clientId: string; clientSecret: string } | null = null;

async function getSpotifyCredentials() {
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

    const credentials = await getSpotifyCredentials();

    // Build the request to Spotify (form-urlencoded)
    const spotifyBody: Record<string, string> = {
      client_id: credentials.clientId,
      client_secret: credentials.clientSecret,
      grant_type,
    };

    if (grant_type === 'authorization_code') {
      if (!request.code) {
        return respond(400, { error: 'Missing authorization code' });
      }
      spotifyBody.code = request.code;
      spotifyBody.redirect_uri = request.redirect_uri || 'tb3://spotify';
      if (request.code_verifier) {
        spotifyBody.code_verifier = request.code_verifier;
      }
    } else if (grant_type === 'refresh_token') {
      if (!request.refresh_token) {
        return respond(400, { error: 'Missing refresh_token' });
      }
      spotifyBody.refresh_token = request.refresh_token;
    }

    const spotifyResponse = await fetch(SPOTIFY_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams(spotifyBody).toString(),
    });

    const spotifyData = await spotifyResponse.json();

    if (!spotifyResponse.ok) {
      return respond(spotifyResponse.status, spotifyData);
    }

    return respond(200, spotifyData);
  } catch (error) {
    console.error('Spotify token proxy error:', error);
    return respond(500, { error: 'Internal server error' });
  }
};
