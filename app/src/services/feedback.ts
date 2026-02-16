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
  playTone(880, 100);
}

export function feedbackExerciseComplete() {
  vibrate([50, 50, 50]);
}

export function feedbackRestComplete() {
  vibrate([50, 50, 50, 50, 50]);
  playTone(523, 100);
  setTimeout(() => playTone(659, 100), 100);
  setTimeout(() => playTone(784, 150), 200);
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
