import animation.{type Animation, type PlayingAnimation}
import asset
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam_community/colour
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
    random.int(0, list.length(stars) - 1) |> random.map(StarIndex)
  let gen_sequence =
    random.fixed_size_list(gen_star_index, length) |> random.map(Sequence)

  random.step(gen_sequence, seed)
}

type StarIndex {
  StarIndex(Int)
}

type Sequence {
  Sequence(List(StarIndex))
}

type StarInfo {
  StarInfo(
    pos: #(Float, Float),
    normal_image: fn() -> p.Image,
    hovered_image: fn() -> p.Image,
    blinking_image: fn() -> p.Image,
  )
}

fn get_star(idx: StarIndex) -> StarInfo {
  let StarIndex(idx) = idx
  let assert Ok(star) =
    stars |> list.index_map(fn(x, i) { #(i, x) }) |> list.key_find(idx)
  star
}

const stars = [
  StarInfo(
    pos: #(600.0, 600.0),
    normal_image: asset.lucy,
    hovered_image: asset.lucy,
    blinking_image: asset.lucy,
  ),
  StarInfo(
    pos: #(950.0, 100.0),
    normal_image: asset.lucy,
    hovered_image: asset.lucy,
    blinking_image: asset.lucy,
  ),
  StarInfo(
    pos: #(1300.0, 600.0),
    normal_image: asset.lucy,
    hovered_image: asset.lucy,
    blinking_image: asset.lucy,
  ),
  StarInfo(
    pos: #(950.0, 850.0),
    normal_image: asset.lucy,
    hovered_image: asset.lucy,
    blinking_image: asset.lucy,
  ),
]

fn view_star(star: StarInfo) {
  p.image(star.normal_image(), width_px: 150, height_px: 150)
  |> p.translate_xy(star.pos.0, star.pos.1)
  |> p.fill(colour.pink)
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

fn title_animation() -> Animation(Picture) {
  let partial_line = fn(start: #(Float, Float), end: #(Float, Float), t: Float) {
    let x = start.0 +. t *. { end.0 -. start.0 }
    let y = start.1 +. t *. { end.1 -. start.1 }
    p.lines([start, #(x, y)])
    |> p.stroke(colour.white, 4.0)
  }

  let animated_line = fn(start, end) {
    let assert Ok(animation) =
      animation.new(
        fn(t) {
          echo t
          partial_line(start, end, t)
        },
        duration: 700.0,
      )
    animation
  }

  animated_line(get_star(StarIndex(0)).pos, get_star(StarIndex(1)).pos)
  |> paint_animation.parallel(
    animated_line(get_star(StarIndex(1)).pos, get_star(StarIndex(2)).pos)
    |> paint_animation.parallel(
      animated_line(get_star(StarIndex(2)).pos, get_star(StarIndex(3)).pos)
      |> paint_animation.parallel(animated_line(
        get_star(StarIndex(3)).pos,
        get_star(StarIndex(0)).pos,
      )),
    ),
  )
}

type Step {
  TitleStep(PlayingAnimation(Picture))
  ShowSequenceStep
}

fn init(_: canvas.Config) -> State {
  State(
    mouse: #(0.0, 0.0),
    dt: 0.0,
    time: 0.0,
    seed: seed.random(),
    step: TitleStep(title_animation() |> animation.start_playing()),
  )
}

fn update(state: State, event: event.Event) -> State {
  case event {
    event.Tick(time) -> {
      let dt = time -. state.time
      let state = State(..state, time:, dt:)

      let step = case state.step {
        TitleStep(anim) -> {
          case animation.play(anim, dt:) {
            option.None -> ShowSequenceStep
            option.Some(updated_anim) -> TitleStep(updated_anim)
          }
        }
        step -> step
      }

      State(..state, step:)
    }
    event.MouseMoved(x, y) -> State(..state, mouse: #(x, y))
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
      ShowSequenceStep -> p.blank()
      TitleStep(anim) -> animation.view_now(anim)
    },
    stars |> list.map(view_star) |> p.combine,

    debug(state),
  ])
}

pub fn main() {
  use <- asset.load_all()
  canvas.interact(init, update, view, "#canvas")
}
