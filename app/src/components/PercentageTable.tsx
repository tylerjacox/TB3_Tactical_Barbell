import { calculatePercentageTable } from '../calculators/oneRepMax';

export function PercentageTable({
  workingMax,
  roundingIncrement,
}: {
  workingMax: number;
  roundingIncrement: 2.5 | 5;
}) {
  const rows = calculatePercentageTable(workingMax, roundingIncrement);

  return (
    <table class="pct-table" aria-label="Percentage table">
      <thead>
        <tr>
          <th>%</th>
          <th style={{ textAlign: 'right' }}>Weight</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((row) => (
          <tr key={row.percentage}>
            <td>{row.percentage}%</td>
            <td>{row.weight} lb</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
