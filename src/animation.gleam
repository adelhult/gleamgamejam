import gleam/option.{type Option}
import paint as p

pub opaque type Animation(a) {
  Animation(
    elapsed_time: Float,
    state: a,
    view: fn(Float, a) -> Option(#(p.Picture, a)),
  )
}

pub fn new(view: fn(Float) -> Option(p.Picture)) -> Animation(Nil) {
  new_with(
    fn(time, _) {
      use picture <- option.then(view(time))
      option.Some(#(picture, Nil))
    },
    state: Nil,
  )
}

pub fn new_with(
  view: fn(Float, a) -> Option(#(p.Picture, a)),
  state initial_state: a,
) -> Animation(a) {
  Animation(elapsed_time: 0.0, state: initial_state, view: fn(time, state) {
    use #(picture, current_state) <- option.then(view(time, state))
    option.Some(#(picture, current_state))
  })
}

pub fn play(
  animation: Animation(a),
  dt dt: Float,
) -> Option(#(Animation(a), p.Picture)) {
  let Animation(elapsed_time:, view:, state:) = animation
  let current_time = elapsed_time +. dt
  use #(picture, current_state) <- option.then(view(current_time, state))
  option.Some(#(
    Animation(..animation, state: current_state, elapsed_time: current_time),
    picture,
  ))
}

pub fn jump_to(
  animation: Animation(a),
  time time: Float,
) -> Option(#(Animation(a), p.Picture)) {
  let Animation(view:, state:, ..) = animation
  use #(picture, current_state) <- option.then(view(time, state))
  option.Some(#(
    Animation(..animation, state: current_state, elapsed_time: time),
    picture,
  ))
}

// FIXME: there should really not be a need of this state parameter, right? Since everything is a pure function of time?

pub fn then(
  first: Animation(a),
  second: Animation(b),
) -> Animation(#(Animation(a), Animation(b))) {
  new_with(
    fn(time, state) {
      let #(first, second) = state
      case jump_to(first, time:) {
        option.None -> jump_to(second, time:)
        option.Some(played_first) -> option.Some(played_first)
      }
    },
    state: #(first, second),
  )
  // case list {
  //   [a] -> a
  //   [a, ..rest] -> {
  //     let view = fn(time) {
  //       case jump_to(a, time:) {
  //         option.Some(#(future_a, pic)) -> {
  //           #(chain([future_a, ..rest]), pic)
  //         }
  //         option.None -> {
  //           let remaining_animations = chain(rest)
  //           remaining_animations.jump_to(a, time:)
  //         }
  //       }
  //     }
  //     Animation(view:, elapsed_time: 0.0)

  //     todo
  //   }
}
