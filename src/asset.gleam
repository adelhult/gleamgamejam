import audio
import paint/canvas

pub fn load_all(callback) {
  canvas.wait_until_loaded(
    [
      pink(),
      pink_light(),
      blue(),
      blue_light(),
      green(),
      green_light(),
      red(),
      red_light(),
      starfield(),
      red_sad(),
      blue_sad(),
      pink_sad(),
      green_sad(),
      telescope(),
    ],
    callback,
  )
}

pub fn pink() {
  canvas.image_from_src("./assets/pink.svg")
}

pub fn pink_light() {
  canvas.image_from_src("./assets/pink_light.svg")
}

pub fn blue() {
  canvas.image_from_src("./assets/blue.svg")
}

pub fn blue_light() {
  canvas.image_from_src("./assets/blue_light.svg")
}

pub fn green() {
  canvas.image_from_src("./assets/green.svg")
}

pub fn green_light() {
  canvas.image_from_src("./assets/green_light.svg")
}

pub fn red() {
  canvas.image_from_src("./assets/red.svg")
}

pub fn red_light() {
  canvas.image_from_src("./assets/red_light.svg")
}

pub fn red_sad() {
  canvas.image_from_src("./assets/red_sad.svg")
}

pub fn blue_sad() {
  canvas.image_from_src("./assets/blue_sad.svg")
}

pub fn green_sad() {
  canvas.image_from_src("./assets/green_sad.svg")
}

pub fn pink_sad() {
  canvas.image_from_src("./assets/pink_sad.svg")
}

pub fn starfield() {
  canvas.image_from_src("./assets/starfield.svg")
}

pub fn telescope() {
  canvas.image_from_src("./assets/telescope.png")
}

pub fn pickup0() {
  audio.new("./assets/pickupCoin0.wav")
}

pub fn pickup1() {
  audio.new("./assets/pickupCoin1.wav")
}

pub fn pickup2() {
  audio.new("./assets/pickupCoin2.wav")
}

pub fn pickup3() {
  audio.new("./assets/pickupCoin3.wav")
}

pub fn game_over() {
  audio.new("./assets/explosion.wav")
}

pub fn level_up() {
  audio.new("./assets/levelUp.wav")
}
