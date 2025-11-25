# gleamjam

watchexec -e gleam -w src -- gleam build
watchexec -r -e mjs,html --no-vcs-ignore -- python -m http.server 3000

[![Package Version](https://img.shields.io/hexpm/v/gleamjam)](https://hex.pm/packages/gleamjam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleamjam/)

```sh
gleam add gleamjam@1
```
```gleam
import gleamjam

pub fn main() -> Nil {
  // TODO: An example of the project in use
}
```

Further documentation can be found at <https://hexdocs.pm/gleamjam>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
