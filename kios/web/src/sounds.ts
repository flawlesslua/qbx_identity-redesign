// Tiny synthesised sounds so the resource ships no audio files.
let ctx: AudioContext | null = null;

function audio(): AudioContext | null {
  try {
    ctx = ctx ?? new AudioContext();
    if (ctx.state === 'suspended') void ctx.resume();
    return ctx;
  } catch {
    return null;
  }
}

function tone(freq: number, start: number, duration: number, volume: number, type: OscillatorType = 'sine') {
  const ac = audio();
  if (!ac) return;
  const t = ac.currentTime + start;
  const osc = ac.createOscillator();
  const gain = ac.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, t);
  gain.gain.setValueAtTime(0.0001, t);
  gain.gain.exponentialRampToValueAtTime(volume, t + 0.008);
  gain.gain.exponentialRampToValueAtTime(0.0001, t + duration);
  osc.connect(gain).connect(ac.destination);
  osc.start(t);
  osc.stop(t + duration + 0.02);
}

function rustle() {
  const ac = audio();
  if (!ac) return;
  const length = Math.floor(ac.sampleRate * 0.18);
  const buffer = ac.createBuffer(1, length, ac.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < length; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / length);
  const src = ac.createBufferSource();
  const filter = ac.createBiquadFilter();
  const gain = ac.createGain();
  filter.type = 'bandpass';
  filter.frequency.value = 2400;
  gain.gain.value = 0.12;
  src.buffer = buffer;
  src.connect(filter).connect(gain).connect(ac.destination);
  src.start();
}

export function play(name: string) {
  switch (name) {
    case 'scan':
      tone(1850, 0, 0.09, 0.06, 'square');
      break;
    case 'paid':
      tone(1046, 0, 0.16, 0.08);
      tone(1568, 0.11, 0.26, 0.08);
      break;
    case 'bag':
      rustle();
      break;
  }
}
