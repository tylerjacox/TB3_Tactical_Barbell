// Dynamic Type detection for iOS (PRD 10.2)
export function probeDynamicType(): number {
  const probe = document.createElement('p');
  probe.style.font = '-apple-system-body';
  probe.style.position = 'absolute';
  probe.style.visibility = 'hidden';
  probe.textContent = 'X';
  document.body.appendChild(probe);
  const computedSize = parseFloat(getComputedStyle(probe).fontSize);
  document.body.removeChild(probe);
  return computedSize / 17; // 17px is default body text
}

export function applyDynamicType() {
  const scale = probeDynamicType();
  document.documentElement.style.setProperty('--dt-scale', String(scale));
}
