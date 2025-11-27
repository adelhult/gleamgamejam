//// Inspired by https://hackage.haskell.org/package/reanimate-1.1.6.0/docs/src/Reanimate.Animation.html

import gleam/float
import gleam/option.{type Option}

pub type Time =
  Float

pub type Duration =
  Float

pub opaque type PlayingAnimation(a) {
  PlayingAnimation(animation: Animation(a), elapsed_time: Duration)
}

pub fn start_playing(animation: Animation(a)) -> PlayingAnimation(a) {
  PlayingAnimation(animation, elapsed_time: 0.0)
}

pub fn play(
  playing: PlayingAnimation(a),
  dt dt: Time,
) -> Option(PlayingAnimation(a)) {
  let time = playing.elapsed_time +. dt
  let duration = playing.animation.duration

  case time >. duration {
    // animation has anded
    True -> {
      option.None
    }
    False -> {
      option.Some(PlayingAnimation(..playing, elapsed_time: time))
    }
  }
}

pub fn view_now(playing: PlayingAnimation(a)) -> a {
  let time = playing.elapsed_time
  let normalized_time =
    case time {
      0.0 -> 0.0
      _ -> time /. playing.animation.duration
    }
    |> float.clamp(0.0, 1.0)

  playing.animation.view(normalized_time)
}

pub opaque type Animation(a) {
  Animation(duration: Time, view: fn(Float) -> a)
}

pub fn new(
  view: fn(Time) -> a,
  duration duration: Duration,
) -> Result(Animation(a), Nil) {
  case duration >. 0.0 {
    False -> Error(Nil)
    True -> Ok(Animation(duration:, view:))
  }
}

pub fn then(first: Animation(a), second: Animation(a)) -> Animation(a) {
  let full_duration = first.duration +. second.duration
  Animation(
    fn(time) {
      case time <. first.duration /. full_duration {
        True -> first.view(time *. first.duration /. full_duration)
        False -> second.view(time *. first.duration /. full_duration)
      }
    },
    duration: full_duration,
  )
}

pub fn parallel(
  first: Animation(a),
  second: Animation(a),
  using merge_op: fn(List(a)) -> a,
) -> Animation(a) {
  let total_duration = float.max(first.duration, second.duration)
  Animation(
    fn(time) {
      let first_time = float.min(1.0, time *. total_duration /. first.duration)
      let second_time =
        float.min(1.0, time *. total_duration /. second.duration)

      merge_op([first.view(first_time), second.view(second_time)])
    },
    duration: total_duration,
  )
}

pub fn empty(
  duration duration: Duration,
  using merge_op: fn(List(a)) -> a,
) -> Result(Animation(a), Nil) {
  new(
    fn(_) {
      let empty_element = merge_op([])
      empty_element
    },
    duration:,
  )
}

pub fn constant(
  picture: a,
  duration duration: Duration,
) -> Result(Animation(a), Nil) {
  new(fn(_) { picture }, duration:)
}

pub fn continue(
  first: Animation(a),
  second: Animation(a),
  using merge_op: fn(List(a)) -> a,
) -> Animation(a) {
  let assert Ok(wait_until_first_complete) =
    empty(duration: first.duration, using: merge_op)

  parallel(first, wait_until_first_complete |> then(second), using: merge_op)
}

pub fn view_at(animation: Animation(a), time time: Time) -> a {
  let time = float.clamp(0.0, time, 1.0)
  animation.view(time)
}
