export function Step4Start({
  startDate,
  onDateChange,
}: {
  startDate: string;
  onDateChange: (date: string) => void;
}) {
  return (
    <div>
      <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 8 }}>Start Training</h2>
      <p style={{ color: 'var(--muted)', fontSize: 15, lineHeight: 1.4, marginBottom: 24 }}>
        Choose when to start your program. Default is today.
      </p>

      <div class="field date-picker-wrapper">
        <label for="start-date">Start Date</label>
        <input
          id="start-date"
          type="date"
          value={startDate}
          onInput={(e) => onDateChange((e.target as HTMLInputElement).value)}
        />
      </div>
    </div>
  );
}
