import gleam/option.{type Option}
import paint as p

pub opaque type Animation {
  Animation(
    elapsed_time: Float,
    step: fn(Float) -> Option(#(Animation, p.Picture)),
  )
}

/// Fixpoint combinator to get around the fact that Gleam does not allow
/// recursive closures. Borrowed from: https://hexdocs.pm/funtil/funtil.html#fix
fn fix(f) {
  fn(x) { f(fix(f), x) }
}

pub fn new(view: fn(Float) -> Option(p.Picture)) -> Animation {
  let step =
    fix(fn(step, time) {
      use picture <- option.then(view(time))
      option.Some(#(Animation(elapsed_time: time, step:), picture))
    })
  Animation(elapsed_time: 0.0, step:)
}

pub fn play(
  animation: Animation,
  dt dt: Float,
) -> Option(#(Animation, p.Picture)) {
  let Animation(elapsed_time:, step:) = animation
  step(elapsed_time +. dt)
}

pub fn then(first: Animation, second: Animation) -> Animation {
  Animation(elapsed_time: 0.0, step: fn(time) {
    case first.step(time) {
      option.None -> {
        let offsetted_second_animation =
          Animation(..second, step: fn(t) { second.step(t -. time) })
        offsetted_second_animation.step(time)
      }
      option.Some(#(cont_first, picture)) -> {
        option.Some(#(then(cont_first, second), picture))
      }
    }
  })
}
