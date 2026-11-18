# Plugin documentation

Velouna plugins are folders with a `plugin.json` and the files it names. There are two kinds:

- **Visualizers**: pictures drawn by GLSL shaders that follow the music, optionally steered by a small Lua script. Plugin interface version 1 (`"api": 1`), Velouna 0.3.0 and newer.
- **Lua plugins**: they react to what the player does, add menus, buttons and dialogs, change what plays, skip segments and bring their own sources into the library. Plugin interface version 2 (`"api": 2`), Velouna 0.4.0 and newer.

Themes come later. Their manifest fields are reserved already.

## Start here

1. **[Getting started](getting-started.md)**: your first visualizer in about fifteen minutes, from an empty folder to a picture that moves with the music.
2. **[Your first Lua plugin](lua-plugins.md#your-first-lua-plugin)**: a plugin that reacts to the player, in two small files.
3. **[Testing and debugging](testing.md)**: how to see changes right away, where errors show up, and how to keep a visualizer smooth.

## Reference

| Page | What's in it |
|---|---|
| [plugin.json](plugin-json.md) | Every field of the manifest: id, names, versions, presets, params, palettes, passes |
| [Shaders](shaders.md) | What Velouna puts in front of your GLSL, every input, the helpers, several passes, feedback and simulations |
| [score.lua](score-lua.md) | The Lua side of a visualizer: `build`, `frame`, `step`, the song analysis, the sandbox and its limits |
| [Lua plugins](lua-plugins.md) | Events, hooks, segments, the player, menus, dialogs, sources, network, storage, settings, permissions and limits |

## Sharing

| Page | What's in it |
|---|---|
| [Your own repo](repos.md) | Build a signed repo, put it on GitHub, let others add it by link, link a single plugin |
| [Forking a plugin](forking.md) | Build on someone else's plugin and publish it in your own repo |
| [Contributing](#contributing-to-the-official-repo) | Get a plugin into this official repo |

## Examples

Each example shows one technique and is commented throughout. All are MIT, so you can copy them into a plugin under any license.

| Example | Shows |
|---|---|
| [`example`](../plugins/example) | The basics: one pass, params, palettes, rings from `score.lua`'s `frame()` |
| [`example-bars`](../plugins/example-bars) | A visualizer without `score.lua`: only the music curves and pulses |
| [`example-trails`](../plugins/example-trails) | Two passes, a half-size `feedback` pass that keeps painting on its last picture |
| [`example-splash`](../plugins/example-splash) | A simulation: `rate: "step"`, operations from `score.lua`'s `step()`, read with `op_tex()` |
| [`example-sections`](../plugins/example-sections) | Song sections, build-up and drop, and two presets sharing one shader |
| [`velounizer`](../plugins/velounizer) | The full thing (GPL-3.0-or-later): Ink is a fluid-like simulation, Aurora and Contour are single-pass |

Lua plugins:

| Example | Shows |
|---|---|
| [`example-log`](../plugins/example-log) | Events and the plugin's own storage: track changes, pauses and seeks in the console |
| [`example-clean-titles`](../plugins/example-clean-titles) | The `track-info` hook: cleaner titles, "Artist – Title" split |
| [`example-segments`](../plugins/example-segments) | The `segments` hook: skip, ask, mute and mark from a file next to the video |
| [`example-notes`](../plugins/example-notes) | Menus, a button in the player bar, dialogs and toasts |
| [`example-effects`](../plugins/example-effects) | A video shader, an audio filter and `velouna.timer` |
| [`example-webhook`](../plugins/example-webhook) | `http`, the settings page and a settings action, only to the home network |
| [`example-module`](../plugins/example-module) | Shared code other plugins load with `require` |
| [`example-rss`](../plugins/example-rss) | A source in the library with search, items that play, a row on the start page |

## Contributing to the official repo

Open a pull request that adds your plugin's folder under `plugins/`. The maintainer rebuilds and signs `repo.json`; don't include `repo.json` or `packages/` changes yourself.

- One plugin per folder, with a license in `plugin.json`.
- No obfuscated code and no downloaded parts: everything the plugin runs is in its folder.
- An `id` of your own (`dev.yourname.something`), not one under `dev.botawesome`.
- Visualizers stay smooth on a mid-range laptop at 1080p (see [Testing](testing.md#keeping-it-smooth)).
- English and, if you can, German names and descriptions.
