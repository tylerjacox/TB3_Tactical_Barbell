# Data Architecture Review — Tactical Barbell PWA

**Reviewer:** Senior Data Architect (Offline-First PWA Specialist)
**Document:** PRD_v2.md
**Date:** 2026-02-15
**Verdict:** The data model is functionally complete but architecturally brittle. The single-record IndexedDB pattern will work for v1 scale but creates an unnecessary ceiling. The schema migration strategy is hand-waved. The storage eviction defense has one layer that does not work as described. Specific changes below.

---

## 1. IndexedDB Schema Design

### Current Design: Single Object Store, Single Record

The PRD specifies:

```
Database: "tb3"
  Store: "app" -> single record (key: "data") containing AppData
```

This means every read and every write touches the entire application state as one serialized blob. Let me evaluate this against the actual access patterns.

### Access Pattern Analysis

| Operation | Frequency | Data Touched | Read/Write |
|---|---|---|---|
| Complete a set | ~30x per workout | activeSession only | R/W |
| View dashboard | Every app open | activeProgram, computedSchedule (next session only) | R |
| View session history | Occasional | sessionHistory (paginated) | R |
| Update 1RM | ~5x per cycle (every 6-12 weeks) | profile.lifts, maxTestHistory, computedSchedule | R/W |
| Change settings | Rare | profile only | R/W |
| Export data | Rare | Everything | R |
| Import data | Rare | Everything | W |

### The Problem with Single-Record

With the single-record approach, completing a set means:

1. Read the entire AppData blob (~50-200KB after months of use)
2. Deserialize it
3. Modify `activeSession.sets[n].completed = true`
4. Serialize the entire blob
5. Write the entire blob back

This is a read-modify-write cycle on the entire application state for a single boolean change. The concerns:

**Transaction contention.** IndexedDB transactions are auto-committed. If two writes overlap (user rapidly double-taps, or a background write from the rest timer state overlaps with a set completion write), the second transaction reads stale data. With a single record, every write contends with every other write. With separate stores, a rest timer state update and a set completion update would be in different object stores and could not conflict.

**Serialization cost.** After 6 months of use, `sessionHistory` alone could be 50-100KB of JSON. Serializing and deserializing this on every set tap is wasteful. It will not cause visible jank on modern iPhones, but it is unnecessary work that compounds with data growth.

**No cursor/index access.** IndexedDB's power is in indexed queries — "give me all sessions where templateId = 'operator' ordered by date." With a single record, all filtering happens in JavaScript after deserializing the entire blob. The PRD's History view (sessions list, newest first) and 1RM progression charts both want indexed access patterns.

### However: The Single-Record Pattern Has Real Benefits

For an app this size with this team, the single-record pattern has legitimate advantages:

1. **Atomic consistency.** The entire app state is always consistent. There is no possibility of `activeProgram` referencing a `computedSchedule` that was partially updated. Every write is a complete snapshot.
2. **Trivial export/import.** Export = read the one record and stringify it. Import = parse and write the one record. No multi-store transaction coordination.
3. **Simple migration.** Transform one object, write it back. No cross-store migration orchestration.
4. **idb-keyval compatibility.** The PRD specifies `idb-keyval` (~600 bytes), which is a simple key-value wrapper. Moving to multiple stores means either a heavier library or a custom wrapper.

### Recommendation: Hybrid Approach

Use the single-record pattern for the core state blob, but extract the two collections that will grow unboundedly into their own object stores with indexes:

```
Database: "tb3" (version 1)
  Store: "app"           -> single record (key: "state") containing CoreState
  Store: "sessions"      -> SessionLog records, keyed by id, indexed on [date, templateId]
  Store: "maxTests"      -> OneRepMaxTest records, keyed by id, indexed on [date, liftName]
```

Where `CoreState` is `AppData` minus `sessionHistory` and `maxTestHistory`:

```typescript
interface CoreState {
  schemaVersion: number;
  profile: UserProfile;
  activeProgram: ActiveProgram | null;
  computedSchedule: ComputedSchedule | null;
  activeSession: ActiveSessionState | null;
  lastBackupDate: string | null;
}
```

This gives you:
- Atomic reads/writes for the hot path (session tracking) on a small object (~2-5KB)
- Indexed queries on session history and 1RM history for the History view
- The export function reads all three stores and merges; import writes to all three in one transaction
- `idb-keyval` can still be used for the `app` store; the two collection stores need a thin custom wrapper (~30 lines) for indexed reads

**If the team rejects this and wants to keep the single-record pattern:** it will work for v1. The performance ceiling is real but distant. A user would need ~500+ completed sessions (roughly 3 years of consistent training) before serialization cost becomes noticeable. But the migration from single-record to multi-store later is a harder migration than starting with multi-store now.

---

## 2. Data Model Completeness

I will walk through every user action and verify the data model supports it.

### Action: Enter 1RM

- **User inputs:** lift name, weight, reps, max type
- **Model writes:** Creates a `LiftEntry` in `profile.lifts` and appends a `OneRepMaxTest` to `maxTestHistory`
- **Gap:** `LiftEntry` stores `weight`, `reps`, `oneRepMax`, `workingMax`. But `OneRepMaxTest` also stores `weight`, `reps`, `calculatedMax`, `maxType`, `workingMax`. The redundancy is intentional (profile has current values, history has all values), but there is no explicit link. If the user updates their squat 1RM, the code must both update the `LiftEntry` in `profile.lifts` AND append to `maxTestHistory`. If either write is missed, the data diverges.
- **Recommendation:** Make `profile.lifts` derived from `maxTestHistory`. The current values for each lift should be computed by taking the most recent `OneRepMaxTest` per `liftName`. This eliminates the dual-write problem. Store the user's `maxType` preference only once in `profile.maxType`, not per-test.

### Action: Start a Program

- **User inputs:** template selection, start date, lift selections (for Zulu/Fighter)
- **Model writes:** Sets `activeProgram`, generates and stores `computedSchedule`
- **Status:** Supported. The `liftSelections` field on `ActiveProgram` covers Zulu/Fighter cluster customization.
- **Gap:** No field to store which lifts the user selected for templates with optional slots (Gladiator's optional Military Press, Mass Protocol's optional Military Press). The `liftSelections` field is typed as `Record<string, string>` which is flexible enough, but the PRD only mentions it for Zulu/Fighter. Clarify that it applies to all templates with customizable lift slots.

### Action: Complete a Set

- **User taps:** "Complete Set" button
- **Model writes:** Updates `activeSession.sets[n].completed = true`, `activeSession.sets[n].actualReps = targetReps`, `activeSession.sets[n].completedAt = now`
- **Status:** Fully supported.
- **Gap:** The `activeSession.sets` array has `exerciseIndex` and `setNumber`, but no field for `targetWeight` or `actualWeight`. If the user overrides the weight mid-session (PRD Section 5.4: "Tap the weight number to override for this session only"), where is the override stored? It is not in `ActiveSessionState`. It needs a `weightOverrides` map or a `targetWeight`/`actualWeight` pair per exercise in the session state.

### Action: Undo Set Completion

- **User taps:** "Undo" within 5-second window
- **Model writes:** Reverses the last set completion
- **Status:** Not explicitly modeled. The undo is ephemeral (in-memory state tracking the last action), and the reversal is just setting `completed = false` and `actualReps = null` on the most recent set. This works with the current model.

### Action: Fail Reps

- **User taps:** rep count to adjust (e.g., got 3 of 5)
- **Model writes:** `activeSession.sets[n].actualReps = 3`
- **Status:** Supported. The `actualReps` field exists and is nullable.

### Action: Complete a Session

- **Model writes:** Converts `activeSession` into a `SessionLog`, appends to `sessionHistory`, advances `activeProgram.currentSession`, clears `activeSession`
- **Gap:** The conversion from `ActiveSessionState` to `SessionLog` requires mapping. `ActiveSessionState` has flat `sets[]` array with `exerciseIndex`. `SessionLog` has nested `exercises[].sets[]`. The mapping is straightforward but must be implemented correctly. The `SessionLog` needs fields from the `computedSchedule` (template name, week, session number) that are partially available in `activeSession` (`programWeek`, `programSession`) but `templateId` is in `activeProgram`, not `activeSession`. If the user switches templates between starting and completing a session (theoretically impossible but defensively important), the `templateId` should be snapshotted into `activeSession` at session start.
- **Recommendation:** Add `templateId` to `ActiveSessionState`.

### Action: Skip a Session

- **Model writes:** Append a `SessionLog` with `status: 'skipped'`, advance `activeProgram.currentSession`
- **Status:** Supported by the model. `SessionLog.status` includes `'skipped'`.

### Action: Change Settings (barbell weight, plate inventory, rounding)

- **Model writes:** Updates `profile`, triggers `computedSchedule` regeneration
- **Status:** Supported.
- **Gap:** When does regeneration happen? Synchronously during the settings save? What if the user is mid-session and changes the barbell weight? The PRD says "Recalculate all future sessions automatically" but the active session in progress shows weights from the old schedule. Does the in-progress session update live? Or does it keep its weights and only future sessions change?
- **Recommendation:** If `activeSession` exists, do not update the active session's weights. Only regenerate the `computedSchedule` for sessions after the current one. Snapshot the session's weights at session start.

### Action: Export Data

- **Model reads:** Entire `AppData`
- **Status:** Supported. The single-record pattern makes this trivial.
- **Gap:** No `exportedAt` timestamp in the export file. Add one for import validation.

### Action: Import Data

- **Model writes:** Replaces entire `AppData`
- **Status:** Supported for full replacement.
- **Gap:** The PRD says "Validates schema before overwriting" but does not define what validation means. See Section 6 below.

### Missing Data: Session Duration Tracking

The `SessionLog` has `durationMinutes?: number` for endurance sessions, but there is no `startedAt` or `completedAt` timestamp pair. For strength sessions, the total workout duration is useful data (and trivially derivable from `activeSession.startedAt` and the last `sets[].completedAt`). Add `completedAt: string` to `SessionLog`.

### Missing Data: Weight Override Tracking in Active Session

As noted above, `ActiveSessionState` has no mechanism to store per-exercise weight overrides. Add:

```typescript
interface ActiveSessionState {
  // ... existing fields ...
  weightOverrides: Record<number, number>;  // exerciseIndex -> overridden weight
}
```

### Missing Data: Session ID Generation

Both `SessionLog.id` and `OneRepMaxTest.id` are typed as `string` but the PRD does not specify how IDs are generated. Use `crypto.randomUUID()` (supported in Safari 15.4+) or a timestamp-based fallback. Do not use auto-incrementing integers — they collide on import.

---

## 3. ComputedSchedule Design

### When is it Generated?

The PRD says: "Pre-computed on program activation. Regenerated on 1RM or settings change."

The triggers for regeneration are:

1. Program activation (new program started)
2. 1RM value changes (any lift)
3. Settings changes affecting weights: rounding increment, barbell weight, max type (true/training)
4. Plate inventory changes (affects `plateBreakdown` and `achievable` fields)

### Invalidation Strategy

The current design has no explicit invalidation. The `computedSchedule` is regenerated in-place — the old one is overwritten. This is correct for a single-user, single-device app. There is no cache key or version number on the computed schedule.

**Problem:** There is no way to verify that the `computedSchedule` is consistent with the current `profile` state. If a bug in the regeneration trigger causes a settings change to skip regeneration, the schedule silently shows stale data. The user sees wrong weights with no indication that anything is wrong.

**Recommendation:** Add a `computedAt` timestamp and a `sourceHash` to `ComputedSchedule`:

```typescript
interface ComputedSchedule {
  computedAt: string;  // ISO timestamp
  sourceHash: string;  // hash of (lifts + settings + templateId) that produced this schedule
  weeks: ComputedWeek[];
}
```

On every render that reads from `computedSchedule`, compute the current source hash and compare. If they diverge, trigger regeneration. This is a cheap integrity check (~1ms to hash the inputs) that catches stale schedules.

### Race Condition: Recomputation During Active Session

**Scenario:** User is mid-workout (activeSession exists). They navigate to Profile, change their Squat 1RM. This triggers computedSchedule regeneration. The active session is reading exercises from the computed schedule.

**Risk:** If the regeneration overwrites `computedSchedule` while the session view is rendering from it, the exercise list could shift. Worse: the `exerciseIndex` in `activeSession.sets` references positions in the old schedule. If the new schedule has different exercise ordering (unlikely for a 1RM change, but possible if lift selections change), the session state becomes inconsistent.

**Recommendation:** The `activeSession` should snapshot its exercise data at session start. It should not read from `computedSchedule` during the session. Add to `ActiveSessionState`:

```typescript
interface ActiveSessionState {
  // ... existing fields ...
  templateId: string;
  exercises: {
    liftName: string;
    targetWeight: number;
    targetSets: number;
    targetReps: number | number[];
    plateBreakdown: { weight: number; count: number }[];
  }[];
}
```

This decouples the active session from the computed schedule entirely. The session becomes a self-contained record of what was prescribed and what happened.

### Regeneration Performance

For Grey Man (the largest template): 12 weeks x 3 sessions x 4 exercises = 144 entries. Each entry requires one plate calculation (~7 iterations). Total: ~1,000 operations. Sub-millisecond on any modern device. Regeneration can be synchronous without concern.

---

## 4. ActiveSession State Machine

### State Representation

The PRD defines these states:

```
NOT_STARTED -> IN_PROGRESS -> COMPLETED
NOT_STARTED -> SKIPPED
IN_PROGRESS -> PAUSED -> IN_PROGRESS (resume)
IN_PROGRESS -> PAUSED -> ABANDONED (>24h timeout)
```

**Problem:** The `ActiveSessionState` interface has no explicit `status` field. The states are implicit:

- `activeSession === null` → NOT_STARTED or no session
- `activeSession !== null` → one of IN_PROGRESS, PAUSED, ABANDONED
- There is no way to distinguish IN_PROGRESS from PAUSED

The PAUSED state happens when the app is backgrounded, which cannot trigger a write (iOS kills the process). So PAUSED is detected on next launch: if `activeSession` exists, the session is implicitly paused.

**This is actually fine.** The distinction between IN_PROGRESS and PAUSED is a UI concern, not a data concern. On launch, if `activeSession` exists, show "Resume workout?" — the data does not need to know whether the user deliberately paused or was interrupted.

**The ABANDONED state needs definition:** If `activeSession.startedAt` is more than 24 hours ago, treat it as abandoned on next launch. Offer "Resume" and "Discard" options. If discarded, convert to a `SessionLog` with `status: 'partial'` (some sets done) or `status: 'skipped'` (no sets done).

**Recommendation:** Add a `status` field to `ActiveSessionState` for clarity, even though it is technically derivable:

```typescript
interface ActiveSessionState {
  status: 'in_progress' | 'paused';
  // ... rest of fields
}
```

Set to `'paused'` before the write that happens on `visibilitychange` (page hidden). This makes the resume prompt more informative.

### Concurrent Writes: Rapid Tapping

**Scenario:** User rapidly taps "Complete Set" three times in under 500ms.

**With the single-record pattern:**
1. Tap 1: Read AppData, modify set 1, write AppData → Transaction T1
2. Tap 2: Read AppData, modify set 2, write AppData → Transaction T2
3. Tap 3: Read AppData, modify set 3, write AppData → Transaction T3

IndexedDB transactions are serialized per-store. T2 will wait for T1 to complete before reading. This means each tap's read sees the previous tap's write. The data is correct but the latency stacks.

**Is this a problem?** No, because:
- IndexedDB transactions complete in <5ms for small objects
- Three stacked transactions complete in <15ms total
- The user cannot physically tap faster than the transaction completes
- Preact's signal-based rendering batches UI updates

**However:** The UI must optimistically update before the IndexedDB write completes. Do not wait for the transaction to commit before updating the set indicator. Write to IndexedDB in the background; if the write fails (which would only happen if IndexedDB is corrupt or quota is exceeded), show an error.

### Write-on-Every-Change Pattern

The PRD says: "Session state is persisted to IndexedDB on every set completion."

**Is this optimal?** Yes, for this app. The alternatives are:

1. **Write on session complete only:** Loses all progress on force-quit. Unacceptable.
2. **Write on a timer (e.g., every 30s):** Could lose up to 30s of progress. Unnecessary complexity.
3. **Write on every change:** ~30 writes per workout, each <5ms. Total I/O: <150ms across a 45-minute workout. Negligible.

The write-on-every-change pattern is correct. Keep it.

### Missing Transition: Session Completion Logic

The state machine does not define the automatic completion trigger. The PRD says the session completes when the user finishes all sets OR explicitly taps "Complete Session." But the data model does not track whether all exercises are done. The completion check is:

```typescript
const allComplete = activeSession.sets.every(s => s.completed);
```

This works for strength sessions. For endurance sessions, the `sets` array would be empty (endurance has no sets). The completion trigger must be different — the user taps a "Complete" button after the duration elapses.

**Recommendation:** Add a `type: 'strength' | 'endurance'` field to `ActiveSessionState`. For endurance sessions, store `enduranceDuration` and `enduranceStartedAt` instead of `sets`.

---

## 5. Schema Migration Strategy

### Current Specification

The PRD says: "On app launch, read `schemaVersion`. If less than current code version, run sequential migration functions (v1->v2, v2->v3, etc.) before rendering."

This is the right approach. Here is the framework that needs to be designed.

### Migration Framework Design

```typescript
// Each migration is a pure function: old data -> new data
type Migration = (data: unknown) => unknown;

const migrations: Record<number, Migration> = {
  // v1 -> v2: added 'unit' field to profile
  2: (data: any) => ({
    ...data,
    schemaVersion: 2,
    profile: { ...data.profile, unit: 'lb' }
  }),
  // v2 -> v3: split maxType from per-test to profile-level
  3: (data: any) => ({
    ...data,
    schemaVersion: 3,
    // ... transformation
  }),
};

function migrateData(data: unknown, targetVersion: number): AppData {
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
```

### Migration Discovery

Migrations are discovered by iterating from `data.schemaVersion` to `CURRENT_SCHEMA_VERSION` (a constant in the code). Each version increment must have a corresponding migration function. Missing migrations are a build-time error (enforce via a test that checks `migrations` has entries for every version from 2 to CURRENT_SCHEMA_VERSION).

### Migration Testing

Every migration function must have a unit test that:
1. Takes a fixture of the old schema version's data
2. Runs the migration
3. Validates the output against the new schema's TypeScript interface
4. Verifies no data loss (all old records present, with transformations applied)

Store test fixtures as JSON files (`test/fixtures/v1-data.json`, `test/fixtures/v2-data.json`, etc.). These fixtures should represent realistic data (not empty state) — include active programs, session history, mid-workout state.

### Failure During Migration

**Problem:** If the migration crashes mid-way (e.g., migration v2->v3 throws an error), the data in IndexedDB is in an unknown state. Was it partially written? Is it still v2? Is it corrupted?

**Solution: Transactional migration with backup.**

```
1. Read current data from IndexedDB
2. Write a backup copy to a separate key ("data_backup") in the same transaction
3. Run migrations in memory (not touching IndexedDB)
4. If all migrations succeed: write migrated data to "data" key, delete "data_backup"
5. If any migration throws: do not write. Show error to user. Data remains at old version.
6. On next launch: if "data_backup" exists, the previous migration failed. Offer recovery.
```

The backup key is insurance against the edge case where the migration succeeds but the write is interrupted (power loss, force-quit during write). On next launch, if both "data" and "data_backup" exist, compare schema versions and keep the one that is consistent.

### Rollback Strategy

There is no rollback. Migrations are forward-only. This is correct for a client-side app:
- The user cannot downgrade the app (PWA updates are automatic)
- If a migration is buggy, ship a new migration that fixes it (v3->v4 that corrects v2->v3's mistake)
- The backup key provides a recovery path if the user contacts support

### IndexedDB Version vs Schema Version

IndexedDB has its own versioning (`db.version`) that triggers `onupgradeneeded`. This is for structural changes to the database (adding/removing object stores, indexes). Keep this separate from the data schema version:

- **IndexedDB version:** Incremented when object stores or indexes change. Triggers `onupgradeneeded` which handles structural migration.
- **Data schema version:** `schemaVersion` field inside the data. Incremented when the shape of the stored data changes. Handled by the migration functions above.

Most releases will only increment the data schema version. IndexedDB version changes are rare (only when adding new object stores, which is a structural change).

---

## 6. Export/Import Design

### What Should Be in the Export?

**Include:**
- `schemaVersion` — so the import can validate and migrate
- `profile` — all user settings and current lift data
- `activeProgram` — current program state (if any)
- `sessionHistory` — all completed session logs
- `maxTestHistory` — all 1RM test entries
- `lastBackupDate` — set to export timestamp
- `exportedAt` — ISO timestamp of export (add this field)
- `appVersion` — the app version that produced the export (add this field)

**Exclude:**
- `computedSchedule` — derived data; regenerated from profile + activeProgram on import
- `activeSession` — mid-workout state should not be exported (it is transient). If the user exports while mid-workout, the active session should be converted to a partial session log first, or excluded with a warning.

**Rationale for excluding computed data:** The computed schedule is deterministic. Including it in the export wastes space and creates a risk: if the import target has a different app version with a bug fix in the schedule computation, the imported computed schedule would have the old bug's output. Always regenerate on import.

### Export Format

```json
{
  "tb3_export": true,
  "exportedAt": "2026-02-15T10:30:00Z",
  "appVersion": "1.0.0",
  "schemaVersion": 1,
  "profile": { ... },
  "activeProgram": { ... },
  "sessionHistory": [ ... ],
  "maxTestHistory": [ ... ]
}
```

The `tb3_export: true` sentinel field allows quick validation that a JSON file is a TB3 export (not some random JSON file the user picked).

### Import Validation

Import validation must check, in order:

1. **File is valid JSON.** Parse with try/catch.
2. **Has `tb3_export: true` sentinel.** If missing, reject: "This file does not appear to be a TB3 backup."
3. **Has `schemaVersion` field.** If missing, reject: "This backup file is from an unrecognized version."
4. **Schema version is not newer than current app.** If `import.schemaVersion > CURRENT_SCHEMA_VERSION`, reject: "This backup is from a newer version of TB3. Please update the app first." This prevents data loss from importing data the app cannot understand.
5. **Schema version is migratable.** Run the migration functions. If they throw, reject with the migration error.
6. **Required fields exist.** Validate that `profile`, `sessionHistory`, and `maxTestHistory` exist and are arrays/objects of the expected shape. Use runtime type checking (not just TypeScript — TypeScript types are erased at runtime).
7. **Data integrity.** Validate that all `SessionLog.id` values are unique, all `OneRepMaxTest.id` values are unique, all lift names are from the known set.

### Importing from a Newer Schema Version

As noted in step 4 above: reject it. The app cannot safely interpret data it does not understand. The error message should tell the user to update the app.

### Partial Import (1RM History Only)

The PRD does not specify partial import, and I recommend against it for v1. Partial import introduces merge logic: what happens when the imported 1RM history overlaps with existing data? Do duplicates get deduplicated? By what key? (ID? Date + lift name?)

For v1: import is a full replacement. "Importing this backup will replace all current data. This cannot be undone. Continue?"

If partial import is needed in the future, define it as a separate feature ("Merge 1RM History") with explicit conflict resolution rules.

### Import and Active Session

If the user has an active session when they import, the import should warn: "You have a workout in progress. Importing will discard your current session. Continue?" The active session cannot be preserved across an import because the imported data may have a different program, different lifts, different everything.

---

## 7. Storage Eviction Defense

### Layer-by-Layer Analysis

**Layer 1: Cookie-based eviction detection.**

> "Check `document.cookie` for `tb3_active=1` (cookies with 1-year expiry survive ITP)."

**This does not work as described.** Safari's Intelligent Tracking Prevention (ITP) caps **all** client-side storage — including cookies set via `document.cookie` — to 7 days for websites that have not been interacted with. The 7-day cap applies to cookies set via JavaScript (first-party script-writable cookies), not just third-party cookies.

Specifically, starting with Safari 16.4 / WebKit (2023), ITP applies a 7-day expiration cap to:
- localStorage
- IndexedDB
- Cookies set via `document.cookie` (JavaScript-set cookies)
- Service Worker registrations
- Cache API

The only cookies that survive ITP are **server-set cookies** (via `Set-Cookie` HTTP header). A PWA running entirely offline has no server to set cookies.

**Conclusion:** The cookie-based detection is unreliable. A 1-year expiry cookie set via JavaScript will be purged at the same time as IndexedDB — making it useless as an eviction detector.

**Alternative for eviction detection:** Use `localStorage` as a secondary check. While localStorage is also subject to the same 7-day eviction, there is a narrow window where one storage mechanism is evicted before the other (implementation-dependent). The more reliable approach:
- On every app launch, write `localStorage.tb3_lastOpen = Date.now()`.
- On every app launch, check if IndexedDB has data.
- If `localStorage.tb3_lastOpen` exists but IndexedDB is empty, eviction occurred.
- If both are empty, either: first launch, or complete eviction (both wiped simultaneously).

Truthfully, there is no fully reliable eviction detection on iOS Safari for an offline PWA. The best defense is prevention (frequent use resets the 7-day clock) and recovery (export/import).

**Stronger alternative: Service Worker `fetch` event marker.** If the service worker is still registered, it has not been evicted. On every fetch event, the service worker can set a flag. If the app loads but the service worker is not registered, eviction likely occurred. However, service worker registration is also subject to the 7-day eviction, so this only helps if the service worker was evicted but IndexedDB survived (unlikely but possible).

**Recommendation:** Replace Layer 1 with: "On launch, attempt to read IndexedDB. If the read returns empty but the app has been installed (detect via `navigator.standalone` or `display-mode: standalone` media query), show a recovery prompt: 'It looks like your data may have been cleared. Restore from a backup?'"

**Layer 2: Periodic backup reminders (7+ days without export).**

This is sound. The reminder interval should match the eviction window: remind at 5 days (giving the user 2 days of buffer before the 7-day eviction clock runs out). After the first reminder, remind again at 6 days, then daily. The reminders should be non-blocking but persistent (e.g., a banner at the top of the dashboard, not just a one-time toast).

**Layer 3: Export/Import via Web Share API.**

This is sound and well-specified. Two implementation notes:
- `navigator.share()` with a `File` object is supported in Safari 15.4+ (iOS 15.4+). For older iOS versions, fall back to creating a download link (`URL.createObjectURL` + `<a download>`).
- The clipboard fallback (`navigator.clipboard.writeText`) is a poor UX for a full data export (the user has to paste it somewhere). Prefer the file-based approach.

**Layer 4: URL-encoded 1RM recovery.**

> "Encode current 1RM values into a shareable URL hash (~200 bytes)."

**This is clever but impractical for real users.** Let me quantify:

A user with all 5 lifts configured:
```
#recovery=sq:400,3,true|bp:315,3,true|dl:500,1,true|mp:150,5,true|wpu:90,5,true
```

That is ~85 characters. Well within URL limits. The user bookmarks this URL. If data is evicted, they navigate to the bookmark, and the app detects the `#recovery` hash and re-creates their 1RM entries.

**Problems:**
1. Users do not bookmark URLs from PWAs. The "share" sheet on iOS does not have a prominent "Add Bookmark" action for PWA URLs.
2. The URL changes every time a 1RM is updated, so the bookmark becomes stale.
3. Safari bookmarks are synced via iCloud, which is a viable recovery vector — but only if the user has iCloud Bookmarks enabled.
4. This only recovers 1RM data. Program history is lost.

**Verdict:** Keep this as a defense layer but do not rely on it. It is a last resort. The primary defense is Layer 3 (regular file exports).

**Layer 5: Write-through on every meaningful action.**

This is correct and essential. See Section 4 above — the write-on-every-change pattern for `activeSession` is the right call. Extend it: every 1RM update, every settings change, every session completion should write immediately. Do not batch or debounce writes.

### Additional Layer: iCloud-backed localStorage Heuristic

One approach not mentioned: store a minimal recovery payload in `localStorage` separately from IndexedDB. While both are subject to the same 7-day eviction, in practice there are edge cases where one survives and the other does not. The `localStorage` payload should be small (just current 1RM values, ~200 bytes) and updated on every 1RM change. This is essentially the URL-encoded recovery data stored in localStorage instead of a URL.

### Recommendation: Emphasize Export as Primary Defense

The PRD should be explicit: **there is no technical solution that prevents data loss from Safari's 7-day eviction policy for users who stop using the app.** The only reliable protection is regular exports. The app should:

1. Show a "Backup your data" prompt after onboarding completes
2. Remind every 5 days
3. Make the export button prominent in Settings (not buried)
4. Show "Last backup: 3 days ago" on the dashboard

---

## 8. Data Integrity

### Invariants That Must Always Hold

**I1. `activeProgram.templateId` references a valid template.**
- Enforced: The template list is hardcoded (7 templates). `templateId` is a string that must match one of the 7 known IDs. Validate on every read.
- Violation scenario: Data import from a future version that adds a template the current app does not know about.
- Remedy: On validation failure, clear `activeProgram` and prompt user to select a new template.

**I2. `computedSchedule` is consistent with current profile lifts and settings.**
- Enforced: Via the `sourceHash` mechanism proposed in Section 3.
- Violation scenario: Settings change without schedule regeneration (bug in change handler).
- Remedy: On hash mismatch, regenerate silently. Log the inconsistency for debugging.

**I3. `activeSession` references valid week/session numbers within the active program.**
- Enforced: `activeSession.programWeek <= computedSchedule.weeks.length` and `activeSession.programSession <= computedSchedule.weeks[week].sessions.length`.
- Violation scenario: User starts a session, then the program is switched (should be prevented by UI, but defensively...).
- Remedy: If the active session references an invalid week/session, discard it with a prompt.

**I4. Session history is immutable.**
- Enforced: The code should never update a `SessionLog` after it is created. The `sessionHistory` array is append-only.
- Violation scenario: A bug that modifies historical sessions when settings change.
- Remedy: Deep-freeze session logs on creation (in development mode). In production, log a warning if a session log's content changes.

**I5. `maxTestHistory` is append-only.**
- Enforced: Same as I4. New tests are appended; old tests are never modified or deleted.
- Violation scenario: A "delete 1RM entry" feature that violates append-only semantics.
- Remedy: If deletion is needed, add a `deleted: boolean` soft-delete flag rather than removing records.

**I6. Every `SessionLog.id` and `OneRepMaxTest.id` is unique.**
- Enforced: Use `crypto.randomUUID()`. Collision probability is negligible.
- Violation scenario: Import of data with duplicate IDs (user imports the same backup twice).
- Remedy: On import, check for ID collisions. If found, reject the import or deduplicate (by preferring the existing record).

**I7. `profile.lifts` has at most one entry per lift name.**
- Enforced: Before adding/updating a lift entry, check for existing entry with the same name.
- Violation scenario: A bug that appends instead of replacing.
- Remedy: On load, deduplicate by keeping the entry with the most recent data.

**I8. `activeProgram.currentWeek` and `currentSession` are within bounds.**
- Enforced: `currentWeek >= 1 && currentWeek <= template.totalWeeks` and similarly for session.
- Violation scenario: Off-by-one error in session advancement logic.
- Remedy: Clamp to valid range on every read. If out of bounds, the program is complete.

### How to Enforce Invariants

Create a `validateAppData(data: AppData): ValidationResult` function that checks all invariants. Run it:
- On app launch (after migration, before rendering)
- After import
- In development: after every write (expensive but catches bugs early)

The validation function returns a list of violations with severity levels:
- **Fatal:** Data is unusable. Show error, offer export of raw data, prompt for re-import.
- **Recoverable:** Data is usable after automatic correction. Apply corrections silently, log the issue.
- **Warning:** Data is usable but suboptimal. Log for debugging.

---

## 9. Storage Size Projections

### Per-Record Size Estimates

**UserProfile:** ~500 bytes (lifts, settings, plate inventories)

**ActiveProgram:** ~200 bytes

**ComputedSchedule (Grey Man, worst case):**
- 12 weeks x 3 sessions x 4 exercises = 144 exercise entries
- Each entry: ~150 bytes (liftName, targetWeight, plateBreakdown array)
- Total: ~21,600 bytes (~22KB)

**ComputedSchedule (Operator, typical):**
- 6 weeks x 6 sessions x 3 exercises = 108 entries (but endurance sessions have 0 exercises)
- 6 weeks x 3 strength sessions x 3 exercises = 54 entries
- Total: ~8,100 bytes (~8KB)

**ActiveSessionState:** ~2KB (sets array for one session)

**OneRepMaxTest (single entry):** ~150 bytes

**SessionLog (single strength session):**
- Header: ~200 bytes (id, date, templateId, week, session, status, notes)
- Exercises: 3-4 exercises x ~300 bytes each (sets array) = ~1,000 bytes
- Total: ~1,200 bytes per session

**SessionLog (endurance session):** ~250 bytes

### Growth Over Time: Grey Man User

Grey Man: 12 weeks x 3 sessions/week = 36 sessions per cycle.

| Time Period | Sessions | Session History Size | 1RM Tests | Total Data |
|---|---|---|---|---|
| 1 cycle (12 weeks) | 36 | 43 KB | 5 | 46 KB |
| 1 year (4 cycles) | 144 | 173 KB | 20 | 180 KB |
| 3 years (12 cycles) | 432 | 518 KB | 60 | 540 KB |
| 5 years (20 cycles) | 720 | 864 KB | 100 | 900 KB |

### Growth Over Time: Operator User (Higher Volume)

Operator: 6 weeks x 6 sessions/week = 36 sessions per cycle, but each cycle is shorter.

| Time Period | Sessions | Session History Size | 1RM Tests | Total Data |
|---|---|---|---|---|
| 1 cycle (6 weeks) | 36 | 43 KB | 5 | 46 KB |
| 1 year (~8 cycles) | 288 | 346 KB | 40 | 360 KB |
| 3 years (~25 cycles) | 900 | 1,080 KB | 125 | 1,120 KB |
| 5 years (~42 cycles) | 1,512 | 1,814 KB | 210 | 1,900 KB |

### Single-Record Performance Ceiling

With the single-record pattern, every write serializes the entire AppData. The cost of `JSON.stringify()` + IndexedDB write:

| Data Size | Stringify Time | IDB Write Time | Total |
|---|---|---|---|
| 50 KB | <1ms | ~2ms | ~3ms |
| 200 KB | ~1ms | ~3ms | ~4ms |
| 500 KB | ~2ms | ~5ms | ~7ms |
| 1 MB | ~4ms | ~8ms | ~12ms |
| 2 MB | ~8ms | ~15ms | ~23ms |

At 2MB (the 5-year Operator user), each set completion tap takes ~23ms of I/O. This is not perceptible (the 16ms frame budget is for rendering, not storage). **The single-record pattern will not hit a performance wall within a realistic usage horizon.**

### 50MB IndexedDB Quota

Safari's IndexedDB quota is implementation-defined but generally ~50MB per origin for non-persistent storage. At the 5-year growth rate of ~1.9MB, the user would need to train for **~130 years** to hit the 50MB quota.

**The quota is not a concern for this app's data model.** The only risk is if the computed schedule cache is accidentally stored multiple times (e.g., a bug that appends instead of replaces). Even then, computed schedules are <25KB each.

### Conclusion on Storage

The single-record pattern is acceptable for v1. The data growth is linear and slow. The 50MB quota will never be reached. If the hybrid approach (Section 1) is adopted, the per-write cost drops further since `CoreState` stays under 30KB indefinitely.

---

## 10. Specific Recommendations

### Critical (Must fix before implementation)

**R1. Derive `profile.lifts` from `maxTestHistory`.**
Remove `profile.lifts` as a separately-maintained array. Instead, compute current lift values from the most recent `OneRepMaxTest` per lift name. This eliminates the dual-write consistency problem where `profile.lifts` and `maxTestHistory` can diverge. The `maxType` and `roundingIncrement` stay on `profile` as user preferences; the per-lift data comes from history.

**R2. Snapshot exercise data into `ActiveSessionState`.**
Add `exercises[]` (with liftName, targetWeight, targetSets, targetReps, plateBreakdown) and `templateId` to the active session state. The active session must be self-contained and not reference `computedSchedule` during the workout. This prevents race conditions when settings change mid-session and makes session-to-log conversion straightforward.

**R3. Add `weightOverrides` to `ActiveSessionState`.**
The PRD specifies that users can override weights per session, but `ActiveSessionState` has no field for this. Add `weightOverrides: Record<number, number>` mapping exercise index to overridden weight.

**R4. Replace the cookie-based eviction detection (Layer 1).**
JavaScript-set cookies are subject to the same 7-day ITP eviction as IndexedDB and localStorage on Safari. The cookie approach provides no additional detection capability. Replace with: detect standalone mode + empty IndexedDB as the eviction signal.

### High Priority (Should fix before implementation)

**R5. Add `computedAt` and `sourceHash` to `ComputedSchedule`.**
Enable staleness detection. On every render that reads computed data, verify the hash matches the current inputs. If stale, regenerate. This catches bugs where settings changes fail to trigger recomputation.

**R6. Define the export format explicitly.**
Include a `tb3_export: true` sentinel, `exportedAt` timestamp, `appVersion` string, and `schemaVersion`. Exclude `computedSchedule` and `activeSession` from exports. Computed data is regenerated on import; active session state is transient.

**R7. Define import validation as a sequential checklist.**
Valid JSON, has sentinel, has schemaVersion, version is not newer than app, migration succeeds, required fields exist, IDs are unique. Reject with a specific error message at each step. Import is a full replacement (no merge).

**R8. Add `completedAt` to `SessionLog`.**
The session start time is in `activeSession.startedAt`, but this is lost when the session converts to a log. Add `startedAt` and `completedAt` to `SessionLog` for duration tracking.

**R9. Design the migration framework with backup-before-migrate.**
Before running migrations, write a backup of the pre-migration data to a separate IndexedDB key. If migration fails, the backup allows recovery. Delete the backup after successful migration.

**R10. Add `status` field to `ActiveSessionState`.**
Add `status: 'in_progress' | 'paused'` to make the session state explicit rather than inferred from context. Update to `'paused'` on `visibilitychange` (page hidden).

### Medium Priority (Should fix before beta)

**R11. Use the hybrid IndexedDB schema.**
Move `sessionHistory` and `maxTestHistory` to separate object stores with indexes on date and liftName. Keep core state (profile, activeProgram, computedSchedule, activeSession) in the single-record store. This improves History view performance and enables future features (date-range queries, per-lift progression charts) without post-launch migration.

**R12. Add `enduranceStartedAt` and `enduranceDurationActual` to ActiveSessionState.**
Endurance sessions need different tracking than strength sessions. The current `sets[]` array does not model duration-based activities. Add endurance-specific fields and a `sessionType: 'strength' | 'endurance'` discriminator.

**R13. Use `crypto.randomUUID()` for ID generation.**
Specify this explicitly. It is supported in Safari 15.4+ (iOS 15.4+). For older devices, provide a fallback: `Date.now().toString(36) + Math.random().toString(36).slice(2)`.

**R14. Shorten the backup reminder interval from 7 days to 5 days.**
The Safari eviction window is 7 days. Reminding at 5 days gives the user 2 days of buffer. After the first reminder, escalate to daily reminders.

**R15. Add a `validateAppData()` integrity check function.**
Run on launch, after migration, and after import. Check all invariants from Section 8. Automatically correct recoverable violations. Surface fatal violations to the user with an export option for raw data.

### Low Priority (Nice to have)

**R16. Add soft-delete to `maxTestHistory`.**
Instead of removing records, add a `deleted: boolean` flag. This preserves the append-only invariant and allows "undo delete" in the future.

**R17. Consider LZ-string compression for exports.**
A 1MB export compresses to ~200KB with LZ-string. This makes clipboard-based sharing viable for larger datasets. The library is ~5KB. Low priority for v1 since exports will be <100KB for the first year.

**R18. Add per-write checksum to the single-record store.**
Write a CRC32 or similar checksum alongside the data. On read, verify the checksum. If mismatched, the data was corrupted (disk error, interrupted write). This is defense-in-depth and has near-zero performance cost.

---

## Summary

The PRD's data architecture is pragmatic and will work for v1. The single-record IndexedDB pattern is simple and sufficient for the data volumes this app will see. The three highest-priority issues are:

1. **The dual-write problem between `profile.lifts` and `maxTestHistory`** (R1). This will cause bugs. Derive `profile.lifts` from history.

2. **The active session is not self-contained** (R2, R3). It depends on `computedSchedule` for exercise data and has no field for weight overrides. Snapshot everything into the session at start time.

3. **The cookie-based eviction detection does not work on Safari** (R4). JavaScript-set cookies are subject to the same 7-day ITP eviction. Replace with a standalone-mode heuristic.

Everything else is hardening — important for resilience but not blocking for implementation.
