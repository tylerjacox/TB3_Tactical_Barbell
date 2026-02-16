import { useState } from 'preact/hooks';
import type { OneRepMaxTest } from '../types';

/** Colors per lift for chart lines */
const LIFT_COLORS: Record<string, string> = {
  Squat: '#C62828',
  Bench: '#42A5F5',
  Deadlift: '#66BB6A',
  'Military Press': '#F9A825',
  'Weighted Pull-up': '#7B1FA2',
};

type TimeRange = 'day' | 'week' | 'month' | 'year' | 'all';

const TIME_RANGES: { key: TimeRange; label: string }[] = [
  { key: 'day', label: 'Day' },
  { key: 'week', label: 'Week' },
  { key: 'month', label: 'Month' },
  { key: 'year', label: 'Year' },
  { key: 'all', label: 'All' },
];

function getCutoffDate(range: TimeRange): number {
  if (range === 'all') return 0;
  const now = new Date();
  switch (range) {
    case 'day': now.setDate(now.getDate() - 1); break;
    case 'week': now.setDate(now.getDate() - 7); break;
    case 'month': now.setMonth(now.getMonth() - 1); break;
    case 'year': now.setFullYear(now.getFullYear() - 1); break;
  }
  return now.getTime();
}

interface Props {
  tests: OneRepMaxTest[];
}

export function MaxChart({ tests }: Props) {
  const [range, setRange] = useState<TimeRange>('all');

  if (tests.length < 2) return null;

  const cutoff = getCutoffDate(range);

  // Filter tests by time range
  const filtered = range === 'all'
    ? tests
    : tests.filter((t) => new Date(t.date).getTime() >= cutoff);

  // Group by lift, sort by date ascending
  const byLift = new Map<string, { date: number; value: number }[]>();
  for (const t of filtered) {
    if (!byLift.has(t.liftName)) byLift.set(t.liftName, []);
    byLift.get(t.liftName)!.push({
      date: new Date(t.date).getTime(),
      value: Math.round(t.workingMax),
    });
  }
  for (const pts of byLift.values()) {
    pts.sort((a, b) => a.date - b.date);
  }

  // Show lifts with 2+ data points for lines, 1 point as a dot
  const lifts = [...byLift.entries()].filter(([, pts]) => pts.length >= 1);

  const noData = lifts.length === 0;

  // Find global min/max for axes
  let minDate = Infinity, maxDate = -Infinity;
  let minVal = Infinity, maxVal = -Infinity;
  for (const [, pts] of lifts) {
    for (const p of pts) {
      if (p.date < minDate) minDate = p.date;
      if (p.date > maxDate) maxDate = p.date;
      if (p.value < minVal) minVal = p.value;
      if (p.value > maxVal) maxVal = p.value;
    }
  }

  // Add padding to value range
  const valRange = maxVal - minVal || 1;
  minVal = Math.floor(minVal - valRange * 0.1);
  maxVal = Math.ceil(maxVal + valRange * 0.1);
  if (minVal < 0) minVal = 0;

  const dateRange = maxDate - minDate || 1;

  // SVG dimensions
  const width = 320;
  const height = 180;
  const padLeft = 40;
  const padRight = 12;
  const padTop = 12;
  const padBottom = 28;
  const chartW = width - padLeft - padRight;
  const chartH = height - padTop - padBottom;

  function x(date: number) {
    return padLeft + ((date - minDate) / dateRange) * chartW;
  }
  function y(val: number) {
    return padTop + chartH - ((val - minVal) / (maxVal - minVal)) * chartH;
  }

  // Y-axis ticks (3-5 ticks)
  const yTicks: number[] = [];
  if (!noData) {
    const yStep = niceStep(maxVal - minVal, 4);
    const yStart = Math.ceil(minVal / yStep) * yStep;
    for (let v = yStart; v <= maxVal; v += yStep) {
      yTicks.push(v);
    }
  }

  // X-axis ticks (date labels)
  const xTicks: { date: number; label: string }[] = [];
  if (!noData) {
    const allDates = [...new Set(lifts.flatMap(([, pts]) => pts.map((p) => p.date)))].sort();
    const step = Math.max(1, Math.floor(allDates.length / 3));
    for (let i = 0; i < allDates.length; i += step) {
      xTicks.push({ date: allDates[i], label: formatDate(allDates[i], range) });
    }
    const lastDate = allDates[allDates.length - 1];
    if (!xTicks.find((t) => t.date === lastDate)) {
      xTicks.push({ date: lastDate, label: formatDate(lastDate, range) });
    }
  }

  return (
    <div class="max-chart">
      {/* Time range selector */}
      <div class="chart-range-bar" role="radiogroup" aria-label="Time range">
        {TIME_RANGES.map((tr) => (
          <button
            key={tr.key}
            class={`chart-range-btn ${range === tr.key ? 'chart-range-active' : ''}`}
            onClick={() => setRange(tr.key)}
            role="radio"
            aria-checked={range === tr.key}
          >
            {tr.label}
          </button>
        ))}
      </div>

      {noData ? (
        <div class="chart-empty">No data in this time range</div>
      ) : (
        <>
          <svg
            viewBox={`0 0 ${width} ${height}`}
            class="max-chart-svg"
            role="img"
            aria-label="1RM progression chart"
          >
            {/* Grid lines */}
            {yTicks.map((v) => (
              <line
                key={v}
                x1={padLeft}
                y1={y(v)}
                x2={width - padRight}
                y2={y(v)}
                stroke="rgba(255,255,255,0.08)"
                stroke-width="1"
              />
            ))}

            {/* Y-axis labels */}
            {yTicks.map((v) => (
              <text
                key={`yl${v}`}
                x={padLeft - 6}
                y={y(v) + 4}
                text-anchor="end"
                class="chart-label"
              >
                {v}
              </text>
            ))}

            {/* X-axis labels */}
            {xTicks.map((t) => (
              <text
                key={`xl${t.date}`}
                x={x(t.date)}
                y={height - 4}
                text-anchor="middle"
                class="chart-label"
              >
                {t.label}
              </text>
            ))}

            {/* Lines + dots per lift */}
            {lifts.map(([liftName, pts]) => {
              const color = LIFT_COLORS[liftName] || '#FF9500';

              if (pts.length === 1) {
                // Single point — just a dot
                return (
                  <circle
                    key={liftName}
                    cx={padLeft + chartW / 2}
                    cy={y(pts[0].value)}
                    r="4"
                    fill={color}
                  />
                );
              }

              const pathD = pts
                .map((p, i) => `${i === 0 ? 'M' : 'L'}${x(p.date)},${y(p.value)}`)
                .join(' ');

              return (
                <g key={liftName}>
                  <path
                    d={pathD}
                    fill="none"
                    stroke={color}
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  />
                  {pts.map((p, i) => (
                    <circle
                      key={i}
                      cx={x(p.date)}
                      cy={y(p.value)}
                      r="3"
                      fill={color}
                    />
                  ))}
                </g>
              );
            })}
          </svg>

          {/* Legend */}
          <div class="max-chart-legend">
            {lifts.map(([liftName]) => (
              <span key={liftName} class="max-chart-legend-item">
                <span
                  class="max-chart-legend-dot"
                  style={{ background: LIFT_COLORS[liftName] || '#FF9500' }}
                />
                {liftName}
              </span>
            ))}
          </div>
        </>
      )}
    </div>
  );
}

/** Pick a "nice" step size for axis ticks */
function niceStep(range: number, targetTicks: number): number {
  const rough = range / targetTicks;
  const mag = Math.pow(10, Math.floor(Math.log10(rough)));
  const norm = rough / mag;
  let nice: number;
  if (norm <= 1.5) nice = 1;
  else if (norm <= 3) nice = 2;
  else if (norm <= 7) nice = 5;
  else nice = 10;
  return nice * mag || 1;
}

function formatDate(ts: number, range: TimeRange): string {
  const d = new Date(ts);
  if (range === 'day') {
    return `${d.getHours()}:${String(d.getMinutes()).padStart(2, '0')}`;
  }
  return `${d.getMonth() + 1}/${d.getDate()}`;
}
