// Storage eviction detection (PRD 6.6)
export function detectEviction(dataEmpty: boolean): boolean {
  const isStandalone =
    window.matchMedia('(display-mode: standalone)').matches ||
    (navigator as any).standalone === true;
  return isStandalone && dataEmpty;
}
