# score.lua

A preset's `score.lua` turns the analysis of the whole song into events for the shaders: rings that start on strong kicks, a simulation fed with splashes, a picture that changes at every drop. It's optional. A visualizer that only needs what's playing right now gets by with the [shader inputs](shaders.md#inputs).

Name it in the preset: `"score": "score.lua"`. Presets may share one script.

## The three functions

```lua
function build(song, ctx) end             -- once per song, seed, params or window shape
function frame(t) return { rip = { ... } } end      -- once per drawn frame
function step(t0, dt, first) return ops, decay end  -- 60 times per second of song time
```

All three are optional. Define them as globals.

### build

```lua
function build(song, ctx)
```

Runs when the visualizer starts, and again when the song, the seed, a param or the picture's shape changes. Each `build` starts in a fresh Lua state, so anything the script computed before is gone. Do the expensive work here: walk the hits, plan where things go, sort them.

`song` is the [analysis](#the-song). `ctx` holds:

| Field | Meaning |
|---|---|
| `ctx.seed` | The seed the user picked (a whole number). Same seed, same picture. |
| `ctx.aw`, `ctx.ah` | Picture width and height in units of its shorter side. A 16:9 window gives `aw = 1.78`, `ah = 1`. |
| `ctx.params` | This preset's params by `id`: `ctx.params.size`. |
| `ctx.react` | The reaction values: `kick`, `snare`, `hats`, `bass`, `voice`, `keys`, `dynamics`, `camera` (see [Shaders](shaders.md#inputs)). |

Positions in `score.lua` use shorter-side units with the origin top left: `x` from 0 to `ctx.aw`, `y` from 0 to `ctx.ah`.

### frame

```lua
function frame(t)
  return { rip = { { x, y, age, strength }, ... } }
end
```

Runs before every drawn frame with the song time `t` in seconds. It may return up to 16 rings, which the shader reads as `F_rip(i)` and `rip_center(i)` (count in `F_cam.w`). What a "ring" looks like is up to your shader: the four numbers can mean anything.

`frame` runs often, so keep it cheap. Don't walk all hits of the song every frame: find the last one with a binary search, as in the [`example`](../plugins/example/score.lua), and walk backwards from there. Return `nil` or `{}` when there's nothing to draw.

### step

```lua
function step(t0, dt, first)
  return ops, decay
end
```

Drives a [simulation](shaders.md#simulations-step-passes): a pass with `"rate": "step"`. Velouna calls it 60 times per second of song time, in order: `t0` is the start of this step in seconds, `dt` is 1/60.

`first` is `true` on the first step after the simulation was cleared: at the start, after a seek, after `build`. Reset any state that depends on earlier steps then. After a seek, steps start up to 20 seconds before the new position and catch up quickly, so `step` sees the time before the jump again.

`ops` is one flat list of numbers, 12 per operation, at most 64 operations per step (more are dropped):

```lua
local ops = {}
-- kind, colour, -, -,   x, y, radius, strength,   -, -, -, -
ops[#ops + 1] = 0; ops[#ops + 1] = 1; ops[#ops + 1] = 0; ops[#ops + 1] = 0
...
```

A small helper keeps that readable:

```lua
local function op(list, ...)
  local n = select("#", ...)
  for i = 1, 12 do list[#list + 1] = (i <= n) and select(i, ...) or 0 end
end

function step(t0, dt, first)
  local ops = {}
  while nexthit <= #hits and hits[nexthit].t < t0 + dt do
    local h = hits[nexthit]
    op(ops, 0, h.c, 0, 0,  h.x, h.y, h.r, h.s)
    nexthit = nexthit + 1
  end
  return ops, 0.99
end
```

The shader gets operation `i` as `op_tex(i, 0)`, `op_tex(i, 1)`, `op_tex(i, 2)` (numbers 1–4, 5–8, 9–12), the count as `u_step.x` and `decay` as `u_step.y` (1 when you return none). What the numbers and the decay mean is your choice; the [`example-splash`](../plugins/example-splash/score.lua) shows one way.

When `first` is true after a seek, find your place again (`nexthit` above) with a binary search for `t0`.

## The song

| Call | Returns |
|---|---|
| `song.dur` | length in seconds |
| `song.bpm` | tempo |
| `song.beat_period` | seconds per beat |
| `song:hits(name)` | `{ {t = seconds, s = strength 0–1}, ... }`, sorted by time. `name`: `kick`, `snare`, `hat`, `keys` |
| `song:count(name)` | number of hits |
| `song:pulse(name, t, tau)` | decaying sum of the hits before `t`, time constant `tau` seconds, at most 1.25 |
| `song:env(name, t)` | curve value 0–1 at `t`. `name`: `mix`, `sub`, `bass`, `drums`, `keys` (also `mids`), `pads` (also `presence`), `high`, `intensity`, `wave` (peak level, for waveforms) |
| `song:beats()` | list of beat times |
| `song:downbeats()` | list of bar start times |
| `song:bar_index(t)` | number of bars started at or before `t` |
| `song:phases(t)` | beat phase, bar phase (two values, 0–1) |
| `song:section(t)` | kind, start, stop, index (1-based) of the section at `t` |
| `song:sections()` | `{ {kind = ..., start = s, stop = s}, ... }` |

Section kinds are `calm`, `groove`, `build` and `drop`. Every song has at least one section; a song without clear structure is one long `groove`.

The analysis comes from the audio file alone: there's no voice separation yet (`env("voc", t)` is 0). It's good at kicks, snares and drops in electronic and pop music and rougher with acoustic music. Write presets that still look fine when a song has few hits.

## Helpers

| Call | Returns |
|---|---|
| `velouna.rng(seed)` | a random number generator |
| `r:f()` | float 0–1 |
| `r:range(a, b)` | float from `a` to `b` |
| `r:below(n)` | whole number 0 to `n` − 1 |
| `r:chance(p)` | `true` with probability `p` |
| `velouna.hash2(a, b)` | a whole number mixed from two whole numbers, for "random but fixed per item" |
| `print(...)` | writes to Velouna's log (see [Testing](testing.md#the-log)) |

Use `velouna.rng(ctx.seed)` instead of `math.random`: the same seed must always give the same picture, and `math.random` differs between runs. For values per hit that must not shift when you change something else, use `velouna.hash2(ctx.seed, i)`.

## The sandbox

`score.lua` runs in Lua 5.4 with `math`, `string`, `table` and `utf8`. There are no files, no network and no `os`, `io`, `require`, `load` or `collectgarbage`.

| Limit | |
|---|---|
| `build` | 3 seconds |
| `frame`, each `step` | 50 milliseconds |
| Memory | 128 MB |

A script that runs over a limit or raises an error stops the preset. The player shows *Visualizer stopped:* with the file, line and message, for example `runtime error: score.lua:15: attempt to index a nil value (local 'h')`.
