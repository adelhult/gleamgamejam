pub type Audio

@external(javascript, "./audio.ffi.mjs", "new_audio")
pub fn new(path: String) -> Audio

@external(javascript, "./audio.ffi.mjs", "play")
pub fn play(audio: Audio, throttle: Bool) -> Nil
