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

fn animate_sequence(seq: Sequence) -> Animated(Picture) {
  case seq {
    Sequence([head, ..rest]) ->
      animate_star(head) |> animation.then(animate_sequence(Sequence(rest)))
    Sequence([]) -> animation.none()
  }
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
    animation.new(fn(time) {
      case time {
        t if t <. 1000.0 ->
          option.Some(p.circle(time *. 0.1) |> p.fill(colour.red))
        t if t <. 3000.0 ->
          option.Some(p.circle(time *. 0.1) |> p.fill(colour.orange))
        t if t <. 4000.0 ->
          option.Some(p.circle(time *. 0.1) |> p.fill(colour.red))
        _ -> option.None
      }
    })

  let square =
    animation.new(fn(time) {
      case time {
        t if t <. 1000.0 ->
          option.Some(p.square(time *. 0.1) |> p.fill(colour.red))
        t if t <. 3000.0 ->
          option.Some(p.square(time *. 0.1) |> p.fill(colour.orange))
        t if t <. 6000.0 ->
          option.Some(p.square(time *. 0.1) |> p.fill(colour.red))
        _ -> option.None
      }
    })

  circle |> animation.then(square)
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

fn view(state: State) -> Picture {
  p.combine([
    //p.rectangle(1920.0, 1080.0) |> p.fill(black()),
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
