import gleam/float
import gleam/option.{type Option}

pub opaque type Animated(a) {
  Animated(Option(#(AnimationState(a), a)))
}

pub fn new(view: fn(Float) -> a, duration duration: Float) {
  let state = new_inner(view, duration:)
  Animated(play_inner(state, dt: 0.0))
}

pub fn play(animated: Animated(a), dt dt: Float) -> Animated(a) {
  case animated {
    Animated(option.Some(#(state, _))) -> {
      Animated(play_inner(state, dt:))
    }
    Animated(option.None) -> animated
  }
}

pub fn then(first: Animated(a), second: Animated(a)) -> Animated(a) {
  case first, second {
    // if both animations actually exist, use the real `then` operation on their state
    // and evaluate the result at this very moment
    Animated(option.Some(#(first_anim, _))),
      Animated(option.Some(#(second_anim, _)))
    -> {
      let new_anim = then_inner(first_anim, second_anim)
      Animated(play_inner(new_anim, dt: 0.0))
    }
    // No need to chain, just use the second one
    Animated(option.None), Animated(option.Some(_)) -> second
    // No need to chain, just use the first one
    Animated(option.Some(_)), Animated(option.None) -> first
    // Just use an empty animation
    Animated(option.None), Animated(option.None) -> none()
  }
}

pub fn view_current(animation: Animated(a)) -> Option(a) {
  case animation {
    Animated(option.Some(#(_, value))) -> option.Some(value)
    Animated(option.None) -> option.None
  }
}

pub fn none() -> Animated(a) {
  Animated(option.None)
}

pub fn constant(picture: a, duration duration: Float) -> Animated(a) {
  new(fn(_) { picture }, duration:)
}

pub fn sequence(seq: List(Animated(a))) -> Animated(a) {
  case seq {
    [] -> none()
    [anim, ..rest] -> anim |> then(sequence(rest))
  }
}

/// This is *really* the proper animation type,
/// the wrapper is just there to make it more convenient to use
/// in TEA style update/view functions without having to do too much pattern matching
type AnimationState(a) {
  AnimationState(
    duration: Float,
    elapsed_time: Float,
    step: fn(Float) -> Option(#(AnimationState(a), a)),
  )
}

fn new_inner(
  view: fn(Float) -> a,
  duration duration: Float,
) -> AnimationState(a) {
  let step =
    fix(fn(step, time) {
      case time >. duration {
        // animation has anded
        True -> {
          option.None
        }
        // if still playing, normalize time and view the current frame
        False -> {
          let normalized =
            case time {
              0.0 -> 0.0
              _ -> time /. duration
            }
            |> float.clamp(0.0, 1.0)
          let picture = view(normalized)
          option.Some(#(
            AnimationState(elapsed_time: time, step:, duration:),
            picture,
          ))
        }
      }
    })
  AnimationState(elapsed_time: 0.0, step:, duration:)
}

fn play_inner(
  animation: AnimationState(a),
  dt dt: Float,
) -> Option(#(AnimationState(a), a)) {
  let AnimationState(elapsed_time:, step:, ..) = animation
  step(elapsed_time +. dt)
}

fn then_inner(
  first: AnimationState(a),
  second: AnimationState(a),
) -> AnimationState(a) {
  AnimationState(
    elapsed_time: first.elapsed_time,
    duration: first.duration +. second.duration,
    step: fn(time) {
      case first.step(time) {
        option.None -> {
          second.step(time -. first.elapsed_time)
        }
        option.Some(#(cont_first, picture)) -> {
          option.Some(#(then_inner(cont_first, second), picture))
        }
      }
    },
  )
}

/// Fixpoint combinator to get around the fact that Gleam does not allow
/// recursive closures. Borrowed from: https://hexdocs.pm/funtil/funtil.html#fix
fn fix(f) {
  fn(x) { f(fix(f), x) }
}
