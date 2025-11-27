import animation
import paint

pub fn continue(first, second) {
  animation.continue(first, second, using: paint.combine)
}

pub fn empty(duration) {
  animation.empty(duration:, using: paint.combine)
}

pub fn parallel(a, b) {
  animation.parallel(a, b, using: paint.combine)
}

pub fn then(first, second) {
  animation.then(first, second)
}
