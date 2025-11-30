import animation.{type Animation, type PlayingAnimation}
import asset
import audio
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import gleam_community/colour
import gleam_community/maths
import paint.{type Picture} as p
import paint/canvas
import paint/event
import paint_animation
import prng/random
import prng/seed

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
    blinking_image: fn() -> p.Image,
    sad_image: fn() -> p.Image,
    sound: fn() -> audio.Audio,
  )
}

fn get_star(id: StarId) -> StarInfo {
  let assert Ok(star) = stars |> list.find(fn(star) { star.id == id })
  star
}

const stars = [
  StarInfo(
    id: StarId(0),
    pos: #(678.0, 430.0),
    normal_image: asset.red,
    blinking_image: asset.red_light,
    sad_image: asset.red_sad,
    sound: asset.pickup0,
  ),
  StarInfo(
    id: StarId(1),
    pos: #(998.0, 130.0),
    normal_image: asset.green,
    blinking_image: asset.green_light,
    sad_image: asset.green_sad,
    sound: asset.pickup1,
  ),
  StarInfo(
    id: StarId(2),
    pos: #(1264.0, 520.0),
    normal_image: asset.blue,
    blinking_image: asset.blue_light,
    sad_image: asset.blue_sad,
    sound: asset.pickup2,
  ),
  StarInfo(
    id: StarId(3),
    pos: #(869.0, 951.0),
    normal_image: asset.pink,
    blinking_image: asset.pink_light,
    sad_image: asset.pink_sad,
    sound: asset.pickup3,
  ),
]

fn view_star(
  star: StarInfo,
  highlight highlight: Bool,
  effect effect: fn(Picture) -> Picture,
) {
  p.image(
    case highlight {
      False -> star.normal_image()
      True -> star.blinking_image()
    },
    width_px: 150,
    height_px: 150,
  )
  |> effect
  |> p.translate_xy(-150.0 /. 2.0, -150.0 /. 2.0)
  |> p.translate_xy(star.pos.0, star.pos.1)
}

fn view_sad_star(star: StarInfo) {
  p.image(star.sad_image(), width_px: 150, height_px: 150)
  |> p.translate_xy(-150.0 /. 2.0, -150.0 /. 2.0)
  |> p.translate_xy(star.pos.0, star.pos.1)
}

type State {
  State(
    level: Int,
    mouse: #(Float, Float),
    time: Float,
    dt: Float,
    seed: seed.Seed,
    step: Step,
  )
}

fn animate_text(text: String, speed speed: Float) -> Animation(String) {
  let duration = speed *. int.to_float(string.length(text) + 1)
  let assert Ok(anim) =
    animation.new(
      fn(t) {
        let length = float.round(int.to_float(string.length(text)) *. t)
        string.slice(text, at_index: 0, length:)
      },
      duration,
    )
  anim
}

fn tutorial_animation() -> Animation(Picture) {
  let assert Ok(wait) = paint_animation.empty(800.0)
  let assert Ok(wait_super_long_time) = paint_animation.empty(60_000.0)

  let text_anim =
    animate_text(
      "Watching the night sky, you notice the Great Diamond asterism shining brighter than ever.",
      speed: 50.0,
    )
    |> animation.map(fn(text) {
      p.text(text, px: 30)
      |> p.translate_y(500.0)
    })
    |> paint_animation.continue(wait)
    |> paint_animation.continue(
      animate_text("Remember the pattern, then repeat it.", speed: 50.0)
      |> animation.map(fn(text) {
        p.text(text, px: 30)
        |> p.translate_y(500.0 +. 70.0 *. 1.0)
      }),
    )
    |> paint_animation.continue(wait)
    |> paint_animation.continue(
      animate_text("Press Space to begin.", speed: 50.0)
      |> animation.map(fn(text) {
        p.text(text, px: 30)
        |> p.translate_y(500.0 +. 70.0 *. 2.0)
      }),
    )
    |> animation.map(p.translate_x(_, 300.0))
    |> animation.map(p.fill(_, colour.white))

  paint_animation.parallel(
    wait
      |> paint_animation.continue(text_anim),
    wait_super_long_time,
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
  TutorialStep(PlayingAnimation(Picture))
  TitleStep(PlayingAnimation(Picture))
  ShowSequenceStep(Sequence, PlayingAnimation(Picture))
  GuessStep(Sequence)
  GameOver
}

fn init(_: canvas.Config) -> State {
  State(
    level: 1,
    mouse: #(0.0, 0.0),
    dt: 0.0,
    time: 0.0,
    seed: seed.random(),
    step: TutorialStep(tutorial_animation() |> animation.start_playing()),
  )
}

fn go_to_show_sequence(state: State) -> State {
  let #(sequence, seed) = random_sequence(state.seed, state.level)

  let view_all =
    stars
    |> list.map(view_star(_, highlight: False, effect: fn(p) { p }))
    |> p.combine
  let assert Ok(start_pause) = animation.constant(view_all, duration: 800.0)

  State(
    ..state,
    seed:,
    step: ShowSequenceStep(
      sequence,
      animation.start_playing(
        start_pause |> animation.then(animate_sequence(sequence)),
      ),
    ),
  )
}

// Really hacky, should absolutely *not* do side effects like this...
fn with_sound(
  animation: Animation(Picture),
  sound: audio.Audio,
) -> Animation(Picture) {
  let assert Ok(sound_anim) =
    animation.new(
      fn(_) {
        audio.play(sound, True)
        p.blank()
      },
      duration: 1.0,
    )
  paint_animation.parallel(sound_anim, animation)
}

fn animate_sequence(sequence: Sequence) -> Animation(Picture) {
  let animate_blink = fn(id: StarId) {
    let assert Ok(anim) =
      animation.new(
        fn(t) {
          stars
          |> list.map(fn(star) {
            case star.id == id {
              False -> view_star(star, highlight: False, effect: fn(p) { p })
              True ->
                view_star(star, highlight: True, effect: fn(p) {
                  let t = maths.sin(t *. maths.pi())
                  echo t
                  p |> p.scale_uniform(1.0 +. t *. 0.07)
                })
            }
          })
          |> p.combine
        },
        duration: 500.0,
      )
    anim
  }

  let view_all =
    stars
    |> list.map(view_star(_, highlight: False, effect: fn(p) { p }))
    |> p.combine

  let Sequence(sequence) = sequence
  let assert Ok(end) = animation.constant(view_all, duration: 100.0)
  let assert Ok(pause) = animation.constant(view_all, duration: 700.0)

  case sequence {
    [] -> end
    [star_id, ..rest] ->
      pause
      |> paint_animation.then(
        animate_blink(star_id)
        |> with_sound(get_star(star_id).sound()),
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
        TutorialStep(anim) -> {
          case animation.play(anim, dt:) {
            // If the long intro animation times out
            option.None ->
              State(
                ..state,
                step: TitleStep(title_animation() |> animation.start_playing()),
              )
            option.Some(updated_anim) ->
              State(..state, step: TutorialStep(updated_anim))
          }
        }
        TitleStep(anim) -> {
          case animation.play(anim, dt:) {
            option.None -> go_to_show_sequence(state)
            option.Some(updated_anim) ->
              State(..state, step: TitleStep(updated_anim))
          }
        }
        ShowSequenceStep(sequence, anim) ->
          case animation.play(anim, dt:) {
            option.None -> State(..state, step: GuessStep(sequence))
            option.Some(updated_anim) ->
              State(..state, step: ShowSequenceStep(sequence, updated_anim))
          }
        GuessStep(Sequence([])) -> {
          audio.play(asset.level_up(), False)
          go_to_show_sequence(State(..state, level: state.level + 1))
        }
        GuessStep(Sequence(_)) -> state
        GameOver -> state
      }

      state
    }
    event.MouseMoved(x, y) -> State(..state, mouse: #(x, y))
    event.MousePressed(event.MouseButtonLeft) -> {
      case state.step {
        GuessStep(Sequence([current, ..rest])) -> {
          let current_star = get_star(current)
          case is_hovering_star(current_star, state.mouse) {
            False ->
              case list.any(stars, is_hovering_star(_, state.mouse)) {
                False -> state
                True -> {
                  audio.play(asset.game_over(), False)
                  State(..state, step: GameOver)
                }
              }
            True -> {
              audio.play(current_star.sound(), False)
              State(..state, step: GuessStep(Sequence(rest)))
            }
          }
        }
        _ -> state
      }
    }
    event.KeyboardPressed(event.KeySpace) -> {
      case state.step {
        GameOver -> go_to_show_sequence(State(..state, level: 1))
        TutorialStep(_) ->
          State(
            ..state,
            step: TitleStep(title_animation() |> animation.start_playing()),
          )
        _ -> state
      }
    }
    _ -> state
  }
}

fn is_hovering_star(star: StarInfo, mouse_pos: #(Float, Float)) {
  let r = 75.0
  let dx = mouse_pos.0 -. star.pos.0
  let dy = mouse_pos.1 -. star.pos.1
  let distance_sq = dx *. dx +. dy *. dy
  distance_sq <=. r *. r
}

const canvas_width = 1920.0

const canvas_height = 1080.0

fn solid_background() {
  p.rectangle(canvas_width, canvas_height) |> p.fill(p.colour_hex("#00243D"))
}

fn telescope(center: #(Float, Float)) {
  let scale = 1.2
  p.image(asset.telescope(), width_px: 4084, height_px: 2297)
  |> p.scale_uniform(scale)
  |> p.translate_xy(
    -4084.0 *. scale /. 2.0 +. center.0,
    -2297.0 *. scale /. 2.0 +. center.1,
  )
}

fn view(state: State) -> Picture {
  case state.step {
    TutorialStep(anim) -> animation.view_now(anim)
    _ -> {
      let level =
        p.text("Level " <> int.to_string(state.level), px: 50)
        |> p.fill(colour.white)
        |> p.translate_xy(100.0, 100.0)

      let game_over = case state.step {
        GameOver ->
          p.text("Game over, press space to restart ", px: 50)
          |> p.fill(colour.white)
          |> p.translate_xy(100.0, 150.0)
        _ -> p.blank()
      }

      p.combine([
        solid_background(),
        p.image(asset.starfield(), width_px: 1920, height_px: 1080),
        case state.step {
          ShowSequenceStep(_, anim) -> animation.view_now(anim)
          TitleStep(anim) ->
            p.combine([
              animation.view_now(anim),
              stars
                |> list.map(view_star(_, False, fn(p) { p }))
                |> p.combine,
            ])
          GuessStep(_) -> {
            stars
            |> list.map(fn(star) {
              view_star(
                star,
                is_hovering_star(star, state.mouse),
                effect: fn(p) { p },
              )
            })
            |> p.combine
          }
          GameOver ->
            stars
            |> list.map(view_sad_star)
            |> p.combine
          TutorialStep(_) -> panic as "unreachable, already handled"
        },
        telescope(state.mouse),
        level,
        game_over,
      ])
    }
  }
}

pub fn main() {
  use <- asset.load_all()
  canvas.interact(init, update, view, "#canvas")
}
