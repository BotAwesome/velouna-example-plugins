# plugin.json

Every plugin folder has a `plugin.json` at its top. Velouna reads it when the plugin is installed, when the list is reloaded and when a repo is built.

```
my-visualizer/
  plugin.json        manifest (required)
  draw.glsl          fragment shader of a pass (any name, any subfolder)
  score.lua          optional: turns the song analysis into events
  preview.webp       optional: picture for the catalog (.png and .jpg work too)
  changes.json       optional: what's new in this version
```

## Top level

```json
{
  "id": "dev.yourname.myvisualizer",
  "name": { "en": "My visualizer", "de": "Mein Visualizer" },
  "description": { "en": "One line about it", "de": "Eine Zeile dazu" },
  "version": "1.0.0",
  "kind": "visualizer",
  "api": 1,
  "velouna": ">=0.3.0",
  "author": "Your name",
  "license": "MIT",
  "permissions": [],
  "visualizer": { ... }
}
```

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Unique, and never changes. Letters, digits, `.`, `-`, `_`, at most 100 characters, with at least one `.`. Use reverse domain style: `dev.yourname.plugin`. Updates and settings are matched by it. |
| `name` | yes | Shown in lists and menus. A [text](#texts). |
| `description` | | One line, shown in the catalog and the installed list. A [text](#texts). |
| `version` | yes | Dotted numbers, `1.0.0`. Raise it for every release: a published version can't change. Compared number by number, so `1.10.0` is newer than `1.9.0`. |
| `kind` | yes | `visualizer`. `lua` and `theme` are reserved for later. |
| `api` | yes | Plugin interface version: `1`. Velouna loads the current and the previous version. |
| `velouna` | | Lowest Velouna version, as `">=0.3.0"`. Older versions of Velouna don't offer the plugin and refuse to load it. |
| `author` | | Your name. Forks add theirs: `"Original Author, You"`. |
| `license` | | SPDX name, for example `MIT`, `GPL-3.0-or-later`, `CC-BY-4.0`. The official repo requires one. |
| `permissions` | | What the plugin may do beyond the basics. Visualizers can't ask for any: leave it empty. |
| `visualizer` | for visualizers | See [below](#visualizer). |

### Texts

Wherever this page says *text*, write either one string or one string per language code:

```json
"name": "Glow"
"name": { "en": "Glow", "de": "Glühen" }
```

Velouna shows the user's language, else English, else the first one.

## visualizer

```json
"visualizer": {
  "needs": "song",
  "presets": [ { ... }, { ... } ]
}
```

| Field | Meaning |
|---|---|
| `needs` | `"song"`: the visualizer uses the analysis of the whole song (beats, hits, sections). Write it; it's the only value for now. |
| `presets` | One or more. The user picks one in the visualizer menu. Presets of one plugin can share files. |

## Presets

```json
{
  "id": "pulse",
  "name": { "en": "Pulse", "de": "Puls" },
  "score": "score.lua",
  "passes": [ { "id": "scene", "shader": "draw.glsl" } ],
  "params": [ ... ],
  "palettes": [ ... ]
}
```

| Field | Meaning |
|---|---|
| `id` | Unique within the plugin. The user's settings for a preset (palette, seed, sliders) are stored by it, so keep it. |
| `name` | A [text](#texts). |
| `score` | Optional. Path of a [score.lua](score-lua.md) inside the plugin folder. |
| `passes` | One or more [passes](#passes). The last one is what the user sees. |
| `params` | Up to 8 [sliders](#params). |
| `palettes` | One or more [palettes](#palettes). Without any, every colour is black. |

### Params

```json
{ "id": "size", "label": { "en": "Size", "de": "Größe" }, "min": 0.3, "max": 2.5, "default": 1.0 }
```

Each param is a slider in the visualizer menu. The shader gets the values in their order, as `F_shape0.x`, `.y`, `.z`, `.w` (params 1–4) and `F_shape1` (5–8). `score.lua` gets them by `id` in `ctx.params`. Velouna keeps the user's values per preset, so renaming an `id` resets that slider.

Changing a param rebuilds the score (`build` runs again), so a script may use them to place things.

### Palettes

```json
{ "name": "Night", "colors": ["#07080f", "#141a33", "#f04a6e", "#ffb35c", "#7fd4ff", "#ff7a8f", "#f2f2f7"] }
```

Seven `#rrggbb` colours, read in the shader as `C(0)` … `C(6)`:

| | 0 | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|---|
| Role | background | background 2 | colour a | colour b | colour c | accent | text |

The roles are a convention: they let users understand palettes across visualizers, and let your shader look right with any of your palettes. `name` is a [text](#texts).

### Passes

Each pass is a fragment shader drawing into its own picture. Passes run in their order, and the last pass is what the user sees.

```json
"passes": [
  { "id": "sim", "shader": "sim.glsl", "scale": 0.5, "format": "rgba16f", "feedback": true, "rate": "step" },
  { "id": "scene", "shader": "draw.glsl", "inputs": ["sim"] }
]
```

| Field | Default | Meaning |
|---|---|---|
| `id` | | Name. Later passes read this pass's picture as `u_<id>`. |
| `shader` | | GLSL file, path inside the plugin. |
| `scale` | `1` | Size relative to the output. `0.5` is a quarter of the pixels, for simulations and blurry layers. |
| `format` | `rgba8` | `rgba8` (0–1, 8 bits) or `rgba16f` (half floats, also negative and above 1). Devices without float targets fall back to `rgba8`. |
| `feedback` | `false` | The pass reads its own last result as `u_prev`: trails, simulations, anything that builds up over time. |
| `rate` | `frame` | `frame`: once per drawn frame. `step`: 60 times per second of song time, in step with `score.lua`'s `step()`. |
| `inputs` | `[]` | Ids of earlier passes this pass reads. Only listed passes are bound. |

How to use them in GLSL is on the [Shaders](shaders.md#several-passes) page.

## preview.webp

A picture for the catalog, put next to `plugin.json`. 16:9, about 640 × 360 and below 100 KB is plenty. A screenshot of the visualizer with your nicest palette works best. Velouna takes `preview.webp`, `preview.png` or `preview.jpg`, in that order.

## changes.json

What's new in this version. A [text](#texts), as a file of its own. Building a repo copies it into `repo.json` next to the version, so Velouna can show it with the update (planned for a later version).

```json
{ "en": "Smoother rings, new palette Forest", "de": "Weichere Ringe, neue Palette Wald" }
```

Update it with every version you publish.
