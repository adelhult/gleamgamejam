My tiny memory game for Gleam Game Jam 2025 (Theme: LUCY IN THE SKY WITH DIAMONDS).

Play at github pages: https://adelhult.github.io/gleamgamejam/


## Development
Recompile Gleam source on changes
```bash
watchexec -e gleam -w src -- gleam build
```
Restart http server
```bash
watchexec -r -e mjs,html --no-vcs-ignore -- python -m http.server 3000
```
