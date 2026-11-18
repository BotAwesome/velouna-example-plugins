# Shaders

Each pass of a preset is a GLSL fragment shader. Velouna draws one rectangle over the pass's picture, so your `main()` runs once per pixel and writes its colour to `o_color`.

## What Velouna puts in front of your file

Write GLSL ES 3.00 **without** a `#version` line. Velouna builds the shader as:

1. `#version 330 core` on desktop (OpenGL 3.3) or `#version 300 es` with `precision highp float;` on Android (GLES 3),
2. its prelude: the inputs and helpers below,
3. `#line 1`, then your file.

So error messages count lines in your file, and everything on this page is declared already. The same file runs on Windows, Linux and Android: stick to what GLSL ES 3.00 allows (no `double`, no implicit `int` → `float` conversion, write `1.0` and not `1`).

After the last pass, Velouna adds vignette, grain and the fade in and out at the start and end of the song. Don't add your own.

## Coordinates

`px()` is the position of the current pixel in the current pass, in pixels, **origin top left, y down**, like most image tools. The pixel centres are at `.5`.

Most visualizers work in centred units where 1.0 is the shorter side, so they look the same in any window shape:

```glsl
vec2 p = (px() - F_res.xy * 0.5) / F_time.w;   // centre is 0, y down
```

`F_res` is the output size. In a pass with a `scale`, use `u_size` (the size of the current pass) instead:

```glsl
float m = min(u_size.x, u_size.y);
vec2 p = px() / m;     // shorter-side units from the top left, like score.lua
```

## Inputs

All values are `vec4`. Curves are smooth and go from 0 to 1. Pulses jump when a hit happens and decay over a fraction of a second.

| Name | x | y | z | w |
|---|---|---|---|---|
| `F_res` | width | height | 1 / width | 1 / height |
| `F_time` | time in seconds | song length | seed (0–1000) | shorter side in pixels |
| `F_au0` | sub | bass | drums | mix |
| `F_au1` | voice (0 for now) | keys | pads | highs |
| `F_au2` | intensity | section gain | build-up 0–1 | drop flash |
| `F_pulse` | kick | snare | hat | keys |
| `F_phase` | beat phase | bar phase | flow | frame number |
| `F_shape0` | param 1 | param 2 | param 3 | param 4 |
| `F_shape1` | param 5 | param 6 | param 7 | param 8 |
| `F_react0` | kick | snare | hats | bass |
| `F_react1` | voice | keys | dynamics | camera |
| `F_cam` | | | | number of rings |

- **Time** is song time: it stops when the song is paused and jumps when the user seeks. Your picture should be a function of time, not of how many frames were drawn, so that seeking looks right. Only `feedback` passes build up over frames.
- **Beat and bar phase** go from 0 on the beat (or bar) to 1 just before the next. `sin(F_phase.x * 6.2831853)` swings once per beat.
- **Flow** (`F_phase.z`) is a slow time that runs faster with bass and intensity and slower in quiet parts. Use it instead of `F_time.x` for drifting backgrounds.
- **Section gain** (`F_au2.y`) is low in calm parts and high in drops. The kick, snare and hat pulses are already multiplied by it.
- **Build-up** (`F_au2.z`) rises from 0 to 1 during a build section. **Drop flash** (`F_au2.w`) is 1 at the start of a drop and fades out.
- **Seed** (`F_time.z`) is the number the user picks in the visualizer menu. Same seed, same picture. `seed_off()` turns it into a 2D offset for noise.
- **Reaction values** (`F_react0`, `F_react1`) say how strongly to react to each part. They have fixed values for now (kick 1, snare 1, hats 0.7, bass 1, voice 1, keys 0.8, dynamics 0.8, camera 0.6). A menu for them is planned: multiply your pulses and curves by them and your visualizer will follow it.

### Palette

`C(i)` returns palette colour `i` as `vec3`: 0 background, 1 background 2, 2–4 colours a–c, 5 accent, 6 text.

### Rings from score.lua

When `score.lua`'s `frame()` returns rings, `int(F_cam.w)` is their count (at most 16), `F_rip(i)` is ring `i` as `{x, y, age, strength}`, and `rip_center(i)` is its centre in the centred units above.

```glsl
for (int i = 0; i < int(F_cam.w); i++) {
    vec4 rp = F_rip(i);
    float ring = exp(-pow((length(p - rip_center(i)) - rp.z * 0.5) / 0.01, 2.0));
    col += C(4) * ring * exp(-rp.z * 2.0) * rp.w;
}
```

## Helpers

| Function | Returns |
|---|---|
| `px()` | pixel position, origin top left |
| `C(i)` | palette colour |
| `gnoise(vec2 p)` | gradient noise, about −0.7 to 0.7, smooth, one feature per unit |
| `fbm(vec2 p, int octaves)` | layered `gnoise`, for clouds and smoke. 3–5 octaves. |
| `hash21(ivec2 p, uint s)` | random float 0–1 per integer position and seed |
| `hash22(ivec2 p, uint s)` | random `vec2` |
| `rot(float a)` | 2D rotation matrix, `rot(a) * p` |
| `seed_off()` | 2D offset that differs per seed, add it to noise positions |
| `rip_center(int i)` | centre of ring `i` |
| `tex_tl(sampler2D s, vec2 uv)` | read a pass picture at `uv` (0–1, top left), filtered |
| `fetch_tl(sampler2D s, ivec2 p)` | read one pixel of a pass picture, top left; 0 outside |
| `op_tex(int i, int k)` | part `k` (0–2) of operation `i` in a `step` pass |

Don't define functions with these names yourself.

## Several passes

Give each pass an `id`. A later pass reads an earlier one when it lists it in `inputs` and declares the sampler:

```json
"passes": [
  { "id": "trail", "shader": "trail.glsl", "scale": 0.5, "format": "rgba16f", "feedback": true },
  { "id": "scene", "shader": "draw.glsl", "inputs": ["trail"] }
]
```

```glsl
// draw.glsl
uniform sampler2D u_trail;

void main() {
    vec2 uv = px() / F_res.xy;
    vec3 trail = tex_tl(u_trail, uv).rgb;
    ...
}
```

Read pass pictures with `tex_tl` and `fetch_tl`, not with `texture`: Velouna stores them bottom-up like OpenGL does, and these helpers flip them so that they match `px()`.

`scale` makes a pass smaller: `0.5` means half the width and half the height, a quarter of the work. Reading a small pass in a full-size one with `tex_tl` smooths it. That's ideal for glows and for simulations, which rarely need every pixel.

`format: "rgba16f"` stores half floats: values below 0 and above 1, and fine steps. Use it for simulations and anything that fades slowly, because `rgba8` stops fading at 1/255 and leaves a visible haze. On a device without float targets, Velouna uses `rgba8` instead, so make sure the result still looks acceptable there.

## Feedback

With `"feedback": true`, a pass reads its own last picture as `u_prev`:

```glsl
uniform sampler2D u_prev;

void main() {
    vec4 last = fetch_tl(u_prev, ivec2(px()));
    vec4 col = last * 0.96;          // fade what was there
    col += vec4(C(2), 1.0) * dot_here();  // paint something new
    o_color = col;
}
```

The picture starts black, and starts again when the window size changes. A `rate: "frame"` feedback pass runs once per drawn frame, so how fast it fades depends on the frame rate. That's fine for trails. For anything that must look the same on every computer, use a `step` pass.

## Simulations: step passes

A pass with `"rate": "step"` runs 60 times per second of **song time**, no matter how fast the screen is. If a frame comes late, Velouna runs several steps. When the user seeks, or the song, seed, params or window size change, Velouna clears the simulation and replays up to 20 seconds before the current position, so the picture is complete right away. Together with `feedback`, that gives a simulation that looks the same on a fast desktop and a slow phone.

Each step, Velouna calls `score.lua`'s [`step()`](score-lua.md#step), which returns a list of operations for this step and a decay factor. The shader gets:

| Name | Meaning |
|---|---|
| `int(u_step.x)` | number of operations in this step (at most 64) |
| `u_step.y` | the decay `step()` returned (1 if none) |
| `op_tex(i, 0)`, `op_tex(i, 1)`, `op_tex(i, 2)` | operation `i`: numbers 1–4, 5–8 and 9–12 as `vec4` |

What the numbers mean is up to you. A common layout is `head = kind, colour, …` and `a = x, y, radius, strength`:

```glsl
uniform sampler2D u_prev;

void main() {
    vec2 p = px() / min(u_size.x, u_size.y);
    vec4 col = fetch_tl(u_prev, ivec2(px())) * u_step.y;
    for (int i = 0; i < int(u_step.x); i++) {
        vec4 head = op_tex(i, 0);
        vec4 a = op_tex(i, 1);
        float s = smoothstep(a.z, a.z * 0.5, length(p - a.xy)) * a.w;
        col = mix(col, vec4(1.0, 0.0, 0.0, 0.0), s);
    }
    o_color = col;
}
```

Store amounts in the channels (for example "how much of colour a") and turn them into colours in a later `frame` pass. Then the user can switch palettes without the simulation starting over. [`example-splash`](../plugins/example-splash) is a short simulation, the Ink preset of the [Velounizer](../plugins/velounizer/ink) a long one.

Step passes only run when the preset's `score.lua` has a `step()` function. Without one, they stay black.

## Things that go wrong

- **Black picture, no error**: the last pass writes `o_color` with alpha 0, or colours below 0. Write `vec4(col, 1.0)` in the last pass.
- **Upside-down layer**: a pass picture read with `texture()` instead of `tex_tl()`.
- **Works on desktop, fails on Android**: usually a `float` written as `1` or a function from desktop GLSL. Android's compiler is stricter.
- **Haze that never goes away**: a slow fade in an `rgba8` pass. Use `rgba16f`, or subtract a small amount as well as multiplying.
- **Stripes in a `scale` pass**: reading it with `fetch_tl` at full-size coordinates. Use `tex_tl` with 0–1 coordinates.

[Testing and debugging](testing.md) shows where errors appear.
