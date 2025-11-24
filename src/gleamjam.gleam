import animation.{type Animation}
import asset
import gleam/float
import gleam/int
import gleam/list
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

fn animate_sequence(seq: Sequence) -> Animation {
  todo
}

fn view_star(pos: #(Float, Float)) {
  p.circle(50.0) |> p.translate_xy(pos.0, pos.1) |> p.fill(colour.pink)
}

type State {
  State(mouse: #(Float, Float), time: Float, dt: Float, seed: seed.Seed)
}

fn init(_: canvas.Config) -> State {
  State(mouse: #(0.0, 0.0), dt: 0.0, time: 0.0, seed: seed.random())
}

fn update(state: State, event: event.Event) -> State {
  case event {
    event.Tick(time) -> State(..state, time:, dt: time -. state.time)
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
    //p.text("Time: " <> float.to_string(state.dt), px: 50)
  //  |> p.translate_xy(80.0, 80.0),
  ])
}

fn view(state: State) -> Picture {
  p.combine([
    //p.rectangle(1920.0, 1080.0) |> p.fill(black()),
    p.image(asset.lucy(), width_px: 128, height_px: 128)
      |> p.translate_xy(100.0, 100.0),
    p.image(asset.lucy(), width_px: 128, height_px: 128),
    stars_positions |> list.map(view_star) |> p.combine,
    debug(state),
    //
  ])
}

pub fn main() {
  use <- asset.load_all()
  canvas.interact(init, update, view, "#canvas")
}
