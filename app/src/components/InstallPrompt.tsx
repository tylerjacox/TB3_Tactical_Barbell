import { useState, useEffect } from 'preact/hooks';
import { IconClose } from './Icons';

export function InstallPrompt() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    const isStandalone = window.matchMedia('(display-mode: standalone)').matches
      || (navigator as any).standalone === true;
    if (!isStandalone) {
      setShow(true);
    }
  }, []);

  if (!show) return null;

  return (
    <div class="install-banner" role="region" aria-label="Install prompt">
      <p>For the best experience, tap <strong>Share</strong> then <strong>Add to Home Screen</strong>.</p>
      <button
        class="dismiss-btn"
        onClick={() => setShow(false)}
        aria-label="Dismiss install prompt"
      >
        <IconClose />
      </button>
    </div>
  );
}
