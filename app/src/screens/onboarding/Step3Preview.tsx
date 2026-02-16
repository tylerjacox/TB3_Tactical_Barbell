import type { ComputedSchedule } from '../../types';
import { WeekSchedule } from '../../components/WeekSchedule';

export function Step3Preview({ schedule }: { schedule: ComputedSchedule | null }) {
  if (!schedule || !schedule.weeks.length) {
    return (
      <div>
        <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 8 }}>Your First Week</h2>
        <p style={{ color: 'var(--muted)' }}>Enter at least one lift to preview your schedule.</p>
      </div>
    );
  }

  return (
    <div>
      <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 8 }}>Your First Week</h2>
      <p style={{ color: 'var(--muted)', fontSize: 15, marginBottom: 16 }}>
        Here's what Week 1 looks like with your numbers.
      </p>
      <WeekSchedule week={schedule.weeks[0]} defaultOpen />
    </div>
  );
}
