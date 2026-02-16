import { appData, currentLifts } from '../state';
import { navigate } from '../router';
import { getTemplate } from '../templates/definitions';
import { generateSchedule, computeSourceHash } from '../templates/schedule';
import { updateAppData } from '../state';
import { getCurrentLifts } from '../state';
import { syncState } from '../services/sync';
import { authState } from '../services/auth';
import { SessionPreview } from '../components/SessionPreview';
import { InstallPrompt } from '../components/InstallPrompt';

export function Dashboard() {
  const data = appData.value;
  const { activeProgram, computedSchedule, lastBackupDate } = data;
  const lifts = currentLifts.value;

  // Check schedule staleness and regenerate if needed
  if (activeProgram && computedSchedule) {
    const currentHash = computeSourceHash(activeProgram, lifts, data.profile);
    if (currentHash !== computedSchedule.sourceHash) {
      // Silent regeneration
      const newSchedule = generateSchedule(activeProgram, lifts, data.profile);
      updateAppData((d) => ({ ...d, computedSchedule: newSchedule }));
    }
  }

  const template = activeProgram ? getTemplate(activeProgram.templateId) : null;

  // Get current session info
  const currentWeek = computedSchedule?.weeks.find(
    (w) => w.weekNumber === activeProgram?.currentWeek,
  );
  const currentSession = currentWeek?.sessions.find(
    (s) => s.sessionNumber === activeProgram?.currentSession,
  );

  // Program progress
  const totalSessions = template
    ? template.durationWeeks * template.sessionsPerWeek
    : 0;
  const completedSessions = activeProgram
    ? (activeProgram.currentWeek - 1) * (template?.sessionsPerWeek || 0) +
      activeProgram.currentSession - 1
    : 0;
  const progressPct = totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0;

  // Backup reminder
  const daysSinceBackup = lastBackupDate
    ? Math.floor((Date.now() - new Date(lastBackupDate).getTime()) / (1000 * 60 * 60 * 24))
    : null;
  const isAuthenticated = authState.value.isAuthenticated;
  const showBackupReminder = !isAuthenticated && (daysSinceBackup === null || daysSinceBackup >= 5);

  // Check if program is complete
  const isProgramComplete = activeProgram && template &&
    activeProgram.currentWeek > template.durationWeeks;

  if (!activeProgram) {
    return (
      <div class="screen">
        <div class="screen-header"><h1 class="tb3-brand">TB3</h1></div>
        <InstallPrompt />
        <div class="empty-state">
          <p>No active program. Set up your lifts and choose a template to get started.</p>
          <button class="btn btn-primary" onClick={() => navigate('program')}>
            Choose a Template
          </button>
        </div>
      </div>
    );
  }

  if (isProgramComplete) {
    return (
      <div class="screen">
        <div class="screen-header"><h1>Program Complete!</h1></div>
        <div class="card" style={{ textAlign: 'center', padding: 24 }}>
          <p style={{ fontSize: 18, marginBottom: 8 }}>
            You've completed {template!.name}!
          </p>
          <p style={{ color: 'var(--muted)', marginBottom: 24 }}>
            TB recommends retesting your maxes before starting a new block.
          </p>
          <button
            class="btn btn-primary"
            style={{ marginBottom: 12 }}
            onClick={() => navigate('profile')}
          >
            Retest 1RM
          </button>
          <button
            class="btn btn-secondary"
            style={{ width: '100%' }}
            onClick={() => navigate('program')}
          >
            Choose New Template
          </button>
        </div>
      </div>
    );
  }

  return (
    <div class="screen">
      <div class="screen-header"><h1 class="tb3-brand">TB3</h1></div>

      <InstallPrompt />

      {showBackupReminder && (
        <div class="backup-reminder" onClick={() => navigate('profile')}>
          {daysSinceBackup === null
            ? "You haven't backed up your data yet. Tap to export."
            : `It's been ${daysSinceBackup} days since your last backup. Tap to export your data.`}
        </div>
      )}

      {/* Active Program */}
      <div class="card">
        <div class="card-title">Active Program</div>
        <div style={{ fontSize: 20, fontWeight: 700, marginBottom: 4 }}>
          {template?.name}
        </div>
        <div style={{ fontSize: 14, color: 'var(--muted)', marginBottom: 8 }}>
          Week {activeProgram.currentWeek} of {template?.durationWeeks}
        </div>
        <div
          class="progress-bar"
          role="progressbar"
          aria-valuenow={Math.round(progressPct)}
          aria-valuemin={0}
          aria-valuemax={100}
          aria-label={`Program progress, week ${activeProgram.currentWeek} of ${template?.durationWeeks}`}
        >
          <div class="progress-bar-fill" style={{ width: `${progressPct}%` }} />
        </div>
      </div>

      {/* Next Session Preview */}
      {currentSession && currentWeek && (
        <div class="card">
          <div class="card-title">
            Next: Session {activeProgram.currentSession}
          </div>
          <SessionPreview session={currentSession} week={currentWeek} />
        </div>
      )}

      {/* Start Workout Button */}
      <button
        class="btn btn-primary btn-large"
        style={{ marginTop: 8 }}
        onClick={() => navigate('session')}
      >
        Start Workout
      </button>

      {/* Quick Actions */}
      <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
        <button
          class="btn btn-secondary"
          style={{ flex: 1 }}
          onClick={() => navigate('profile')}
        >
          Update Maxes
        </button>
      </div>

      {/* Sync indicator */}
      {syncState.value.lastSyncedAt && (
        <div style={{ textAlign: 'center', marginTop: 16, fontSize: 12, color: 'var(--muted)' }}>
          Last synced: {new Date(syncState.value.lastSyncedAt).toLocaleDateString()}
        </div>
      )}
    </div>
  );
}
