# Getting started

This page builds a small visualizer from an empty folder: a glowing disc that breathes with the bass, jumps on every kick and gets a slider and two colour sets. Along the way you'll set up the loop you'll use for every plugin: change a file, click **Reload**, look.

You need Velouna 0.3.0 or newer on Windows or Linux, a text editor and a song to play. You don't need a compiler or any other tool.

## 1. Make the folder

Make a folder called `glow` anywhere and put a file `plugin.json` in it:

```json
{
  "id": "dev.yourname.glow",
  "name": "Glow",
  "description": "A disc that glows with the music",
  "version": "0.1.0",
  "kind": "visualizer",
  "api": 1,
  "velouna": ">=0.3.0",
  "author": "Your name",
  "license": "MIT",
  "permissions": [],
  "visualizer": {
    "needs": "song",
    "presets": [
      {
        "id": "glow",
        "name": "Glow",
        "passes": [ { "id": "scene", "shader": "draw.glsl" } ],
        "palettes": [
          { "name": "Night", "colors": ["#07080f", "#141a33", "#f04a6e", "#ffb35c", "#7fd4ff", "#ff7a8f", "#f2f2f7"] }
        ]
      }
    ]
  }
}
```

Replace `yourname` with something that is yours, for example your GitHub name. The `id` is how Velouna tells plugins apart, so it must never collide with someone else's and never change once you've shared the plugin. Every field is explained in [plugin.json](plugin-json.md).

## 2. Write the shader

Next to it, make `draw.glsl`:

```glsl
void main() {
    // Centred coordinates: 1.0 is the shorter side of the picture.
    vec2 p = (px() - F_res.xy * 0.5) / F_time.w;

    float bass = F_au0.y;     // smooth bass curve, 0..1
    float kick = F_pulse.x;   // jumps on a kick, then decays

    float r = 0.18 * (1.0 + 0.3 * bass + 0.25 * kick);
    float d = length(p);

    vec3 col = C(0);                                       // background
    col += C(2) * exp(-max(d - r, 0.0) * 9.0) * (0.4 + kick); // glow
    col = mix(col, C(3), smoothstep(r, r - 0.004, d));     // disc

    o_color = vec4(col, 1.0);
}
```

There's no `#version` line and no `uniform` for the music: Velouna puts a prelude in front of your file that declares everything. `px()` is the pixel position, `F_au0`, `F_pulse` and the other `F_` values carry the music, and `C(i)` is colour `i` of the palette. [Shaders](shaders.md) lists them all.

## 3. Load it into Velouna

While you work on a plugin, keep it in Velouna's plugins folder and edit it there:

| System | Plugins folder |
|---|---|
| Windows | `%APPDATA%\Velouna\plugins\` |
| Linux | `~/.config/Velouna/plugins/` |

Copy the `glow` folder into it. (To find the folder, open **Settings → Extensions → Installed**, choose **⋯ → Show in Explorer** (Linux: **Show in file manager**) on any plugin and go one folder up.)

Then, in **Settings → Extensions → Installed**, click **Reload**. Glow shows up in the list. Switch it on.

## 4. Look at it

Play a song. A visualizer button shows up in the player bar as soon as a visualizer plugin is switched on: click it to show the visualizer, click its arrow to pick **Glow**. The first time a song plays with a visualizer, Velouna analyses it for a few seconds ("Visualizer: analysing the song …"). The result is cached.

If the shader has a mistake, the picture stays empty and the player shows *Visualizer stopped:* with the compiler's message and line number. Fix the file and click **Reload**.

## 5. Add a slider

Params become sliders in the visualizer menu. Add this to the preset in `plugin.json`, next to `passes`:

```json
"params": [
  { "id": "size", "label": "Size", "min": 0.3, "max": 2.5, "default": 1.0 }
]
```

The shader reads params in their order: the first four as `F_shape0.x` … `.w`, the next four as `F_shape1`. Use it:

```glsl
float r = 0.18 * F_shape0.x * (1.0 + 0.3 * bass + 0.25 * kick);
```

Click **Reload**. The slider is in the visualizer menu.

## 6. Use the reaction values

`F_react0` and `F_react1` say how strongly a visualizer should react to each part of the music: kick, snare, hats, bass, then voice, keys, dynamics and camera. For now they have fixed values (kick 1, snare 1, hats 0.7, bass 1, keys 0.8 …). Velouna will get a menu to change them; multiply each pulse and curve by its value now, and your visualizer follows that menu later.

```glsl
float bass = F_au0.y * F_react0.w;
float kick = F_pulse.x * F_react0.x;
```

## 7. A second colour set

Add a palette to `palettes`. Each has seven colours: background, background 2, colours a, b, c, accent, text.

```json
{ "name": "Forest", "colors": ["#050b08", "#0f2419", "#5fd38a", "#e8d36a", "#a8f0ff", "#9cffc4", "#eef7f0"] }
```

Reload, and the menu offers both. Write your shader so that any palette looks right: use `C(0)` and `C(1)` for dark areas and `C(2)` to `C(5)` for what lights up.

## 8. Names in more languages

`name`, `description` and every `label` can be one string or one text per language:

```json
"name": { "en": "Glow", "de": "Glühen" }
```

Velouna shows the user's language, else English.

## 9. Events from the song: score.lua

Pulses and curves react to what's playing right now. For anything that needs the whole song, for example rings that start on each strong kick, or something that changes at a drop, add a `score.lua`. Velouna analyses the song once and hands your script the beats, hits and sections.

Add `"score": "score.lua"` to the preset and create the file:

```lua
local kicks = {}
local cx, cy = 0.5, 0.5

function build(song, ctx)
  -- ctx.aw, ctx.ah: picture width and height in units of its shorter side
  cx, cy = ctx.aw / 2, ctx.ah / 2
  kicks = {}
  for _, h in ipairs(song:hits("kick")) do
    if h.s > 0.3 then kicks[#kicks + 1] = h.t end
  end
end

function frame(t)
  local rip = {}
  for i = #kicks, 1, -1 do            -- newest first
    local age = t - kicks[i]
    if age > 1.5 or #rip == 16 then break end
    if age >= 0 then rip[#rip + 1] = { cx, cy, age, 1 } end
  end
  return { rip = rip }
end
```

`build` runs once per song, `frame` once per drawn frame. Each ring is `{x, y, age, strength}`, with x and y in shorter-side units from the top left. The shader gets the count as `F_cam.w` and ring `i` as `F_rip(i)` and `rip_center(i)`:

```glsl
for (int i = 0; i < int(F_cam.w); i++) {
    vec4 rp = F_rip(i);
    float front = r + rp.z * 0.5;
    col += C(4) * exp(-pow((length(p - rip_center(i)) - front) / 0.01, 2.0)) * exp(-rp.z * 2.0) * rp.w;
}
```

The [`example`](../plugins/example) plugin is this whole page finished, with a faster lookup for the rings. [score.lua](score-lua.md) has everything the script can do.

## 10. Share it

When you're happy with it:

1. Copy the folder out of Velouna's plugins folder to where you keep your plugins, for example `my-plugins/glow`.
2. Set the `version` you want to publish (`1.0.0`).
3. Build a repo: **Settings → Extensions → Own repo** packs and signs everything. [Your own repo](repos.md) explains it, including how to put it on GitHub.

From then on, every change gets a higher `version`, so users get the update.

## Next

- [Testing and debugging](testing.md): the log, typical mistakes, keeping it smooth.
- The [examples](README.md#examples): two passes and trails, simulations, song sections.
