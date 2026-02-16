// Haptic + Audio feedback (PRD 10.6)
import { appData } from '../state';

let audioCtx: AudioContext | null = null;

function getAudioCtx(): AudioContext {
  if (!audioCtx) audioCtx = new AudioContext();
  return audioCtx;
}

function vibrate(pattern: number | number[]) {
  const mode = appData.value.profile.soundMode;
  if (mode === 'off') return;
  if (navigator.vibrate) navigator.vibrate(pattern);
}

function playTone(freq: number, duration: number, type: OscillatorType = 'sine') {
  const mode = appData.value.profile.soundMode;
  if (mode !== 'on') return;
  try {
    const ctx = getAudioCtx();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = type;
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.15, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration / 1000);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + duration / 1000);
  } catch { /* Audio may not be available */ }
}

export function feedbackSetComplete() {
  vibrate(50);
  playTone(660, 60);
  setTimeout(() => playTone(880, 80), 60);
}

export function feedbackExerciseComplete() {
  vibrate([50, 50, 50]);
  playTone(784, 100);
  setTimeout(() => playTone(1047, 150), 100);
  setTimeout(() => playTone(1319, 200), 250);
}

export function feedbackRestComplete() {
  vibrate([50, 50, 50, 50, 50]);
  playTone(523, 100);
  setTimeout(() => playTone(659, 100), 100);
  setTimeout(() => playTone(784, 150), 200);
  speak('Go');
}

export function feedbackUndo() {
  vibrate(150);
}

export function feedbackSessionComplete() {
  vibrate([150, 50, 50, 50, 150]);
  playTone(523, 150);
  setTimeout(() => playTone(659, 150), 150);
  setTimeout(() => playTone(784, 200), 300);
}

export function feedbackError() {
  vibrate([30, 30, 30]);
  playTone(220, 100, 'square');
}

// --- Voice Announcements ---

const speechAvailable = typeof window !== 'undefined' && 'speechSynthesis' in window;

export function isSpeechAvailable(): boolean {
  return speechAvailable;
}

function getSelectedVoice(): SpeechSynthesisVoice | null {
  const name = appData.value.profile.voiceName;
  if (!name) return null;
  const voices = speechSynthesis.getVoices();
  return voices.find((v) => v.name === name) ?? null;
}

export function getAvailableVoices(): SpeechSynthesisVoice[] {
  return speechSynthesis
    .getVoices()
    .filter((v) => v.lang.startsWith('en'))
    .sort((a, b) => a.name.localeCompare(b.name));
}

function speak(text: string) {
  if (!speechAvailable) return;
  if (!appData.value.profile.voiceAnnouncements) return;
  try {
    speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(text);
    u.rate = 1.1;
    const voice = getSelectedVoice();
    if (voice) u.voice = voice;
    speechSynthesis.speak(u);
  } catch { /* Speech may not be available */ }
}

export function speakTest(text: string, voiceName: string | null) {
  if (!speechAvailable) return;
  try {
    speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(text);
    u.rate = 1.1;
    if (voiceName) {
      const voice = speechSynthesis.getVoices().find((v) => v.name === voiceName);
      if (voice) u.voice = voice;
    }
    speechSynthesis.speak(u);
  } catch { /* Speech may not be available */ }
}

const MILESTONE_LABELS: Record<number, string> = {
  60: 'One minute',
  30: 'Thirty seconds',
  15: 'Fifteen seconds',
  5: '5', 4: '4', 3: '3', 2: '2', 1: '1',
};

export function feedbackVoiceMilestone(remainingMs: number): number | null {
  const sec = Math.ceil(remainingMs / 1000);
  const label = MILESTONE_LABELS[sec];
  if (label) {
    speak(label);
    return sec;
  }
  return null;
}
