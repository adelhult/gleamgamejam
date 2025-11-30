const AUDIO_CACHE = new Map();
const THROTTLE_MS = 800; // adjust as needed

export function new_audio(path) {
  if (AUDIO_CACHE.has(path)) {
    return AUDIO_CACHE.get(path);
  }

  console.log("created audio");
  const audio = new Audio(path);

  // attach state for throttling this specific effect
  audio._lastPlayTime = 0;

  AUDIO_CACHE.set(path, audio);
  return audio;
}

export function play(audio, throttle) {
  const now = performance.now();

  // Throttle audio instance
  if (throttle && now - audio._lastPlayTime < THROTTLE_MS) {
    console.log("play throttled for", audio.src);
    return;
  }

  audio._lastPlayTime = now;

  console.log("played", audio.src);
  audio.currentTime = 0;

  audio.play();
}
