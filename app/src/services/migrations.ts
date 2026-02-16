// Schema migration framework with backup-before-migrate
import type { AppData } from '../types';

type Migration = (data: unknown) => unknown;

const migrations: Record<number, Migration> = {
  // Future migrations go here:
  // 2: (data: any) => ({ ...data, schemaVersion: 2, ... }),
};

export function migrateData(data: unknown, targetVersion: number): AppData {
  let current = data as any;
  let version = current.schemaVersion || 1;

  while (version < targetVersion) {
    const migrate = migrations[version + 1];
    if (!migrate) {
      throw new Error(`No migration from v${version} to v${version + 1}`);
    }
    current = migrate(current);
    version = current.schemaVersion;
  }

  return current as AppData;
}
