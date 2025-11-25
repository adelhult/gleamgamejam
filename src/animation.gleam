import gleam/option.{type Option}
import paint as p

pub opaque type Animated(a) {
  Animation(elapsed_time: Float, step: fn(Float) -> Option(#(Animated(a), a)))
}

pub fn new(view: fn(Float) -> Option(a)) -> Animated(a) {
  let step =
    fix(fn(step, time) {
      use picture <- option.then(view(time))
      option.Some(#(Animation(elapsed_time: time, step:), picture))
    })
  Animation(elapsed_time: 0.0, step:)
}

pub fn play(animation: Animated(a), dt dt: Float) -> Option(#(Animated(a), a)) {
  let Animation(elapsed_time:, step:) = animation
  step(elapsed_time +. dt)
}

pub fn then(first: Animated(a), second: Animated(a)) -> Animated(a) {
  Animation(elapsed_time: first.elapsed_time, step: fn(time) {
    case first.step(time) {
      option.None -> {
        second.step(time -. first.elapsed_time)
      }
      option.Some(#(cont_first, picture)) -> {
        option.Some(#(then(cont_first, second), picture))
      }
    }
  })
}

pub fn timeout(animation: Animated(a), max_time: Float) -> Animated(a) {
  todo
}

pub fn none() -> Animated(a) {
  new(fn(_) { option.None })
}

pub fn constant(picture: a) -> Animated(a) {
  new(fn(_) { option.Some(picture) })
}

/// Fixpoint combinator to get around the fact that Gleam does not allow
/// recursive closures. Borrowed from: https://hexdocs.pm/funtil/funtil.html#fix
fn fix(f) {
  fn(x) { f(fix(f), x) }
}
