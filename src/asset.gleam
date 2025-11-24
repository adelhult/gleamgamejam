import paint/canvas

pub fn load_all(callback) {
  canvas.wait_until_loaded([lucy()], callback)
}

pub fn lucy() {
  canvas.image_from_query("#lucy")
}
