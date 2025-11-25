import animation.{type Animated}
import asset
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam_community/colour
import paint.{type Picture} as p
import paint/canvas
import paint/event
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
    random.int(0, list.length(stars_positions) - 1) |> random.map(StarIndex)
  let gen_sequence =
    random.fixed_size_list(gen_star_index, length) |> random.map(Sequence)

  random.step(gen_sequence, seed)
}

fn animate_star(head: StarIndex) -> Animated(Picture) {
  todo
}

type StarIndex {
  StarIndex(Int)
}

type Sequence {
  Sequence(List(StarIndex))
}

fn black() {
  let assert Ok(black) = colour.from_rgb_hex(0x1e1e1e)
  black
}

// TODO: maybe match exactly with https://en.wikipedia.org/wiki/Great_Diamond
const stars_positions = [
  #(600.0, 600.0),
  #(950.0, 150.0),
  #(1300.0, 600.0),
  #(950.0, 950.0),
]

fn my_animation() -> Animated(Picture) {
  let circle =
    animation.new(
      fn(time) {
        case time {
          t if t <. 0.1 -> p.circle(time *. 150.0 +. 50.0) |> p.fill(colour.red)
          t if t <. 0.5 ->
            p.circle(time *. 150.0 +. 50.0) |> p.fill(colour.orange)
          t if t <. 0.8 -> p.circle(time *. 150.0 +. 50.0) |> p.fill(colour.red)
          _ -> p.circle(time *. 150.0 +. 50.0) |> p.fill(colour.red)
        }
      },
      duration: 5000.0,
    )

  let square =
    animation.new(
      fn(time) {
        case time {
          t if t <. 0.1 -> p.square(time *. 150.0 +. 50.0) |> p.fill(colour.red)
          t if t <. 0.5 ->
            p.square(time *. 150.0 +. 50.0) |> p.fill(colour.orange)
          t if t <. 0.8 -> p.square(time *. 150.0 +. 50.0) |> p.fill(colour.red)
          _ -> p.square(time *. 150.0 +. 50.0) |> p.fill(colour.red)
        }
      },
      duration: 3000.0,
    )

  //circle |> animation.then(square)
  animation.sequence([circle, square])
}

fn view_star(pos: #(Float, Float)) {
  p.circle(50.0) |> p.translate_xy(pos.0, pos.1) |> p.fill(colour.pink)
}

type State {
  State(
    mouse: #(Float, Float),
    time: Float,
    dt: Float,
    seed: seed.Seed,
    anim: option.Option(#(Animated(Picture), Picture)),
  )
}

fn init(_: canvas.Config) -> State {
  State(
    mouse: #(0.0, 0.0),
    dt: 0.0,
    time: 0.0,
    seed: seed.random(),
    anim: my_animation() |> animation.play(0.0),
  )
}

fn play(
  anim: option.Option(#(Animated(Picture), Picture)),
  dt dt: Float,
) -> option.Option(#(Animated(Picture), Picture)) {
  case anim {
    option.None -> option.None
    option.Some(#(anim, _)) -> animation.play(anim, dt:)
  }
}

fn update(state: State, event: event.Event) -> State {
  case event {
    event.Tick(time) -> {
      let dt = time -. state.time
      State(..state, time:, dt:, anim: play(state.anim, dt:))
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
    p.text("Time: " <> float.to_string(state.dt), px: 50)
      |> p.translate_xy(80.0, 80.0),
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
    p.image(asset.lucy(), width_px: 128, height_px: 128)
      |> p.translate_xy(100.0, 100.0),
    p.image(asset.lucy(), width_px: 128, height_px: 128),
    stars_positions |> list.map(view_star) |> p.combine,
    case state.anim {
      option.None -> p.blank()
      option.Some(#(_, picture)) -> picture
    }
      |> p.translate_xy(500.0, 500.0),
    debug(state),
  ])
}

pub fn main() {
  use <- asset.load_all()
  canvas.interact(init, update, view, "#canvas")
}
