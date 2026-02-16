import {
  DynamoDBClient,
  PutItemCommand,
  QueryCommand,
} from '@aws-sdk/client-dynamodb';
import { marshall, unmarshall } from '@aws-sdk/util-dynamodb';

const client = new DynamoDBClient({});
const TABLE = process.env.TABLE_NAME!;

interface SyncRequest {
  lastSyncedAt: string | null;
  push: {
    profile: Record<string, unknown> | null;
    activeProgram: Record<string, unknown> | null;
    newSessions: Array<Record<string, unknown>>;
    newMaxTests: Array<Record<string, unknown>>;
  };
}

interface SyncResponse {
  serverTime: string;
  pull: {
    profile: Record<string, unknown> | null;
    activeProgram: Record<string, unknown> | null;
    newSessions: Array<Record<string, unknown>>;
    newMaxTests: Array<Record<string, unknown>>;
  };
}

export const handler = async (event: {
  requestContext?: { authorizer?: { jwt?: { claims?: { sub?: string } } } };
  body?: string;
}): Promise<{ statusCode: number; headers: Record<string, string>; body: string }> => {
  try {
    const userId = event.requestContext?.authorizer?.jwt?.claims?.sub;
    if (!userId) {
      return respond(401, { error: 'Unauthorized' });
    }

    const body: SyncRequest = JSON.parse(event.body || '{}');
    const serverTime = new Date().toISOString();
    const pk = `USER#${userId}`;

    // Track pushed item keys to filter from pull
    const pushedKeys = new Set<string>();

    // --- PUSH PHASE ---

    // Push profile (last-write-wins by lastModified)
    if (body.push?.profile) {
      const pushed = await pushSingleton(pk, 'PROFILE', body.push.profile);
      if (pushed) pushedKeys.add('PROFILE');
    }

    // Push activeProgram (last-write-wins by lastModified)
    if (body.push?.activeProgram) {
      const pushed = await pushSingleton(pk, 'PROGRAM', body.push.activeProgram);
      if (pushed) pushedKeys.add('PROGRAM');
    }

    // Push new sessions (append-only, idempotent by PK/SK)
    if (body.push?.newSessions?.length) {
      for (const session of body.push.newSessions) {
        const sk = `SESSION#${session.id}`;
        await putItem(pk, sk, session);
        pushedKeys.add(sk);
      }
    }

    // Push new max tests (append-only, idempotent by PK/SK)
    if (body.push?.newMaxTests?.length) {
      for (const test of body.push.newMaxTests) {
        const sk = `MAXTEST#${test.id}`;
        await putItem(pk, sk, test);
        pushedKeys.add(sk);
      }
    }

    // --- PULL PHASE ---
    // Query all items modified since client's last sync
    const lastSyncedAt = body.lastSyncedAt || '1970-01-01T00:00:00Z';
    const items = await queryModifiedSince(pk, lastSyncedAt);

    const pull: SyncResponse['pull'] = {
      profile: null,
      activeProgram: null,
      newSessions: [],
      newMaxTests: [],
    };

    for (const item of items) {
      const sk = item.SK as string;

      // Filter out items the client just pushed (avoid echo)
      if (pushedKeys.has(sk)) continue;

      // Remove DynamoDB keys from the data payload
      const { PK, SK, ...data } = item;

      if (sk === 'PROFILE') {
        pull.profile = data;
      } else if (sk === 'PROGRAM') {
        pull.activeProgram = data;
      } else if (sk.startsWith('SESSION#')) {
        pull.newSessions.push(data);
      } else if (sk.startsWith('MAXTEST#')) {
        pull.newMaxTests.push(data);
      }
    }

    return respond(200, { serverTime, pull });
  } catch (err) {
    console.error('Sync error:', err);
    return respond(500, { error: 'Internal server error' });
  }
};

/**
 * Push a singleton item (profile/program) using last-write-wins.
 * Only writes if client's lastModified is newer than server's.
 */
async function pushSingleton(
  pk: string,
  sk: string,
  data: Record<string, unknown>,
): Promise<boolean> {
  const lastModified = data.lastModified as string;
  if (!lastModified) return false;

  try {
    await client.send(
      new PutItemCommand({
        TableName: TABLE,
        Item: marshall(
          { PK: pk, SK: sk, ...data },
          { removeUndefinedValues: true },
        ),
        ConditionExpression:
          'attribute_not_exists(PK) OR lastModified < :clientModified',
        ExpressionAttributeValues: marshall({
          ':clientModified': lastModified,
        }),
      }),
    );
    return true;
  } catch (err: unknown) {
    if ((err as { name?: string }).name === 'ConditionalCheckFailedException') {
      return false; // Server has newer data, skip
    }
    throw err;
  }
}

/**
 * Put an append-only item (session/maxTest). Idempotent — PutItem with
 * same PK/SK overwrites with identical data.
 */
async function putItem(
  pk: string,
  sk: string,
  data: Record<string, unknown>,
): Promise<void> {
  await client.send(
    new PutItemCommand({
      TableName: TABLE,
      Item: marshall(
        { PK: pk, SK: sk, ...data },
        { removeUndefinedValues: true },
      ),
    }),
  );
}

/**
 * Query all items for a user modified since a given timestamp.
 * Handles pagination.
 */
async function queryModifiedSince(
  pk: string,
  lastSyncedAt: string,
): Promise<Array<Record<string, unknown>>> {
  const items: Array<Record<string, unknown>> = [];
  let lastEvaluatedKey: Record<string, any> | undefined;

  do {
    const result = await client.send(
      new QueryCommand({
        TableName: TABLE,
        KeyConditionExpression: 'PK = :pk',
        FilterExpression: 'lastModified > :since',
        ExpressionAttributeValues: marshall({
          ':pk': pk,
          ':since': lastSyncedAt,
        }),
        ExclusiveStartKey: lastEvaluatedKey,
      }),
    );

    if (result.Items) {
      for (const item of result.Items) {
        items.push(unmarshall(item));
      }
    }

    lastEvaluatedKey = result.LastEvaluatedKey;
  } while (lastEvaluatedKey);

  return items;
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
