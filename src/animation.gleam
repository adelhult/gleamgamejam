import gleam/float
import gleam/option.{type Option}

/// A finite animation
pub opaque type Animated(a) {
  Animation(
    duration: Float,
    elapsed_time: Float,
    step: fn(Float) -> Option(#(Animated(a), a)),
  )
}

pub fn new(view: fn(Float) -> a, duration duration: Float) -> Animated(a) {
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
            Animation(elapsed_time: time, step:, duration:),
            picture,
          ))
        }
      }
    })
  Animation(elapsed_time: 0.0, step:, duration:)
}

pub fn play(animation: Animated(a), dt dt: Float) -> Option(#(Animated(a), a)) {
  let Animation(elapsed_time:, step:, ..) = animation
  step(elapsed_time +. dt)
}

pub fn then(first: Animated(a), second: Animated(a)) -> Animated(a) {
  Animation(
    elapsed_time: first.elapsed_time,
    duration: first.duration +. second.duration,
    step: fn(time) {
      case first.step(time) {
        option.None -> {
          second.step(time -. first.elapsed_time)
        }
        option.Some(#(cont_first, picture)) -> {
          option.Some(#(then(cont_first, second), picture))
        }
      }
    },
  )
}

pub fn constant(picture: a, duration duration: Float) -> Animated(a) {
  new(fn(_) { picture }, duration:)
}

/// Fixpoint combinator to get around the fact that Gleam does not allow
/// recursive closures. Borrowed from: https://hexdocs.pm/funtil/funtil.html#fix
fn fix(f) {
  fn(x) { f(fix(f), x) }
}
