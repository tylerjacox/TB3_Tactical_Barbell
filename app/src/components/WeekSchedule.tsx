import { useState } from 'preact/hooks';
import type { ComputedWeek } from '../types';
import { SessionPreview } from './SessionPreview';
import { IconChevronDown } from './Icons';

export function WeekSchedule({
  week,
  defaultOpen = false,
  isCurrent = false,
}: {
  week: ComputedWeek;
  defaultOpen?: boolean;
  isCurrent?: boolean;
}) {
  const [open, setOpen] = useState(defaultOpen);

  const setsLabel = week.setsRange[0] === week.setsRange[1]
    ? `${week.setsRange[0]}`
    : `${week.setsRange[0]}-${week.setsRange[1]}`;
  const repsLabel = Array.isArray(week.repsPerSet)
    ? week.repsPerSet.join(',')
    : `${week.repsPerSet}`;

  return (
    <div class="week-schedule card">
      <button
        class="week-header"
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        style={{ width: '100%', background: 'none', border: 'none', color: 'inherit' }}
      >
        <h3>
          Week {week.weekNumber}
          {isCurrent && <span class="text-accent"> (Current)</span>}
        </h3>
        <span class="week-pct">
          {week.percentage}% — {setsLabel}x{repsLabel}
          <span style={{ marginLeft: 8, transform: open ? 'rotate(180deg)' : 'none', display: 'inline-block', transition: 'transform 0.2s' }}>
            <IconChevronDown />
          </span>
        </span>
      </button>
      {open && week.sessions.map((session, i) => (
        <SessionPreview key={i} session={session} week={week} />
      ))}
    </div>
  );
}
