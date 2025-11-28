import animation.{type Animation, type PlayingAnimation}
import asset
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam_community/colour
import gleam_community/maths
import paint.{type Picture} as p
import paint/canvas
import paint/event
import paint_animation
import prng/random
import prng/seed

// type State =
// Intro
//  (draw lines in the shape of a diamond)
//  (draw title text)
//  fade out
// Show Sequence
// Play (Sequence, correct)
// Failed (what thing)

fn random_sequence(seed: seed.Seed, length: Int) -> #(Sequence, seed.Seed) {
  let gen_star_index =
    random.int(0, list.length(stars) - 1) |> random.map(StarId)
  let gen_sequence =
    random.fixed_size_list(gen_star_index, length) |> random.map(Sequence)

  random.step(gen_sequence, seed)
}

type StarId {
  StarId(Int)
}

type Sequence {
  Sequence(List(StarId))
}

type StarInfo {
  StarInfo(
    id: StarId,
    pos: #(Float, Float),
    normal_image: fn() -> p.Image,
    hovered_image: fn() -> p.Image,
    blinking_image: fn() -> p.Image,
  )
}

fn get_star(id: StarId) -> StarInfo {
  let assert Ok(star) = stars |> list.find(fn(star) { star.id == id })
  star
}

const stars = [
  StarInfo(
    id: StarId(0),
    pos: #(600.0, 600.0),
    normal_image: asset.lucy,
    hovered_image: asset.lucy,
    blinking_image: asset.lucy,
  ),
  StarInfo(
    id: StarId(1),
    pos: #(950.0, 100.0),
    normal_image: asset.lucy,
    hovered_image: asset.lucy,
    blinking_image: asset.lucy,
  ),
  StarInfo(
    id: StarId(2),
    pos: #(1300.0, 600.0),
    normal_image: asset.lucy,
    hovered_image: asset.lucy,
    blinking_image: asset.lucy,
  ),
  StarInfo(
    id: StarId(3),
    pos: #(950.0, 850.0),
    normal_image: asset.lucy,
    hovered_image: asset.lucy,
    blinking_image: asset.lucy,
  ),
]

fn view_star(star: StarInfo, highlight highlight: Bool) {
  let star_pic =
    p.image(star.normal_image(), width_px: 150, height_px: 150)
    |> p.translate_xy(-150.0 /. 2.0, -150.0 /. 2.0)

  // temp
  case highlight {
    False -> star_pic
    True -> p.circle(75.0) |> p.fill(colour.white) |> p.concat(star_pic)
  }
  |> p.translate_xy(star.pos.0, star.pos.1)
}

type State {
  State(
    mouse: #(Float, Float),
    time: Float,
    dt: Float,
    seed: seed.Seed,
    step: Step,
  )
}

fn test_anim() {
  let assert Ok(circle) =
    animation.new(
      fn(t) {
        p.circle(30.0 +. 80.0 *. t)
        |> p.translate_xy(
          200.0 *. maths.cos(maths.pi() *. 2.0 *. t),
          200.0 *. maths.sin(maths.pi() *. 2.0 *. t),
        )
      },
      duration: 3000.0,
    )
  circle
  |> animation.map(p.fill(_, colour.pink))
  |> animation.ease(fn(t) { t *. t })
  |> animation.parallel(
    circle
      |> animation.map(p.translate_y(_, 300.0))
      |> animation.map(p.fill(_, colour.orange))
      |> animation.ease(fn(t) { t *. t *. t }),
    using: p.combine,
  )
}

fn title_animation() -> Animation(Picture) {
  let partial_line = fn(start: #(Float, Float), end: #(Float, Float), t: Float) {
    let x = start.0 +. t *. { end.0 -. start.0 }
    let y = start.1 +. t *. { end.1 -. start.1 }
    p.lines([start, #(x, y)])
    |> p.stroke(colour.white, 4.0)
  }

  let animated_line = fn(start, end) {
    let assert Ok(animation) =
      animation.new(fn(t) { partial_line(start, end, t) }, duration: 500.0)
    animation
  }

  let assert Ok(wait) = paint_animation.empty(500.0)

  animated_line(get_star(StarId(0)).pos, get_star(StarId(1)).pos)
  |> paint_animation.continue(animated_line(
    get_star(StarId(1)).pos,
    get_star(StarId(2)).pos,
  ))
  |> paint_animation.continue(animated_line(
    get_star(StarId(2)).pos,
    get_star(StarId(3)).pos,
  ))
  |> paint_animation.continue(animated_line(
    get_star(StarId(3)).pos,
    get_star(StarId(0)).pos,
  ))
  |> animation.ease(fn(t) { t *. t *. t })
  |> paint_animation.continue(wait)
}

type Step {
  TitleStep(PlayingAnimation(Picture))
  ShowSequenceStep(Sequence, PlayingAnimation(Picture))
  GuessStep(Sequence, correct_so_far: Int)
}

fn init(_: canvas.Config) -> State {
  let assert Ok(wait) = animation.empty(6000.0, using: p.combine)
  State(
    mouse: #(0.0, 0.0),
    dt: 0.0,
    time: 0.0,
    seed: seed.random(),
    step: TitleStep(title_animation() |> animation.start_playing()),
  )
}

fn go_to_show_sequence(state: State) -> State {
  let #(sequence, seed) = random_sequence(state.seed, 3)

  State(
    ..state,
    seed:,
    step: ShowSequenceStep(
      sequence,
      animation.start_playing(animate_sequence(sequence)),
    ),
  )
}

fn go_to_guess_step(sequence: Sequence) -> Step {
  GuessStep(sequence, correct_so_far: 0)
}

fn animate_sequence(sequence: Sequence) -> Animation(Picture) {
  let view_blink = fn(id: StarId) -> Picture {
    stars
    |> list.map(fn(star) { view_star(star, highlight: star.id == id) })
    |> p.combine
  }

  let view_all =
    stars
    |> list.map(view_star(_, highlight: False))
    |> p.combine

  let Sequence(sequence) = sequence
  let assert Ok(end) = paint_animation.empty(1.0)
  let assert Ok(pause) = animation.constant(view_all, duration: 500.0)

  case sequence {
    [] -> end
    [star_id, ..rest] ->
      pause
      |> paint_animation.then(
        animation.constant(view_blink(star_id), duration: 1000.0)
        |> result.lazy_unwrap(fn() { panic as "duration 0" }),
      )
      |> animation.then(animate_sequence(Sequence(rest)))
  }
}

fn update(state: State, event: event.Event) -> State {
  case event {
    event.Tick(time) -> {
      let dt = time -. state.time
      let state = State(..state, time:, dt:)

      let state = case state.step {
        TitleStep(anim) -> {
          case animation.play(anim, dt:) {
            option.None -> go_to_show_sequence(state)
            option.Some(updated_anim) ->
              State(..state, step: TitleStep(updated_anim))
          }
        }
        ShowSequenceStep(sequence, anim) ->
          case animation.play(anim, dt:) {
            // TODO: implement 'guess' step
            option.None -> State(..state, step: go_to_guess_step(sequence))
            option.Some(updated_anim) ->
              State(..state, step: ShowSequenceStep(sequence, updated_anim))
          }
        GuessStep(_, _) -> state
      }

      state
    }
    event.MouseMoved(x, y) -> State(..state, mouse: #(x, y))
    // TODO: handle keypresses in guess mode
    event.MousePressed(event.MouseButtonLeft) -> state
    _ -> state
  }
}

fn debug(state: State) {
  p.combine([
    p.text(
      "Mouse: "
        <> int.to_string(float.round(state.mouse.0))
        <> ", "
        <> int.to_string(float.round(state.mouse.1)),
      px: 50,
    )
    |> p.translate_xy(50.0, 50.0),
    // p.text("Time: " <> float.to_string(state.dt), px: 50)
  //   |> p.translate_xy(80.0, 80.0),
  ])
}

const canvas_width = 1920.0

const canvas_height = 1080.0

fn solid_background() {
  p.rectangle(canvas_width, canvas_height) |> p.fill(p.colour_hex("#003459"))
}

fn view(state: State) -> Picture {
  p.combine([
    solid_background(),
    case state.step {
      ShowSequenceStep(_, anim) -> animation.view_now(anim)
      TitleStep(anim) -> animation.view_now(anim)
      GuessStep(sequence, correct_so_far:) -> {
        todo
      }
    },
    debug(state),
  ])
}

pub fn main() {
  use <- asset.load_all()
  canvas.interact(init, update, view, "#canvas")
}
