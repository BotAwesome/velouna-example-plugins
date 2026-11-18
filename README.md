# Velouna example plugins

Small, commented plugins for [Velouna](https://github.com/BotAwesome/velouna), the media player, and the documentation for writing your own.
Each example shows one technique. Read it, try it, copy what you need: all examples are MIT.

The plugins Velouna offers in its built-in catalog live in [velouna-plugins](https://github.com/BotAwesome/velouna-plugins). The examples are not in that catalog, so they don't fill up the list for people who only want to use Velouna.

## Try the examples in Velouna

1. In Velouna open **Settings → Extensions → Repos** and choose **Add repo**.
2. Paste `https://github.com/BotAwesome/example-plugins` and confirm.
3. The examples now show up under **Catalog**. Tick what you want and choose **Install selected**.

To add a single example, link its folder instead, for example `https://github.com/BotAwesome/example-plugins/tree/main/plugins/example-bars`.

## The examples

### Visualizers

Pictures that follow the music: a GLSL shader, and if you like a small `score.lua`. Velouna 0.3.0 and newer.

| Example | Shows |
|---|---|
| [Example](plugins/example) | The basics: one pass, params, palettes, rings from `score.lua` |
| [Bars](plugins/example-bars) | A visualizer without `score.lua`: only the music curves and pulses |
| [Trails](plugins/example-trails) | Two passes and a feedback pass that keeps painting on its last picture |
| [Splash](plugins/example-splash) | A simulation driven by `step()` in `score.lua` |
| [Sections](plugins/example-sections) | Song sections, build-up and drop, and two presets sharing one shader |

### Lua plugins

Plugins that react to the player, add menus and buttons, change what plays and bring their own sources. Velouna 0.4.0 and newer.

| Example | Shows |
|---|---|
| [Track log](plugins/example-log) | Events and the plugin's own storage |
| [Clean titles](plugins/example-clean-titles) | The `track-info` hook: removes "(Official Video)" and the like, splits "Artist – Title" |
| [Segments from a file](plugins/example-segments) | The `segments` hook: skip, ask, mute and mark parts of a video |
| [Notes](plugins/example-notes) | Menu entries, a player bar button, dialogs and toasts |
| [Effects](plugins/example-effects) | A video shader, an audio filter and a sleep timer |
| [Webhook](plugins/example-webhook) | `http`, a settings page and a settings action |
| [Module](plugins/example-module) | Shared code other plugins load with `require` |
| [Podcasts (RSS)](plugins/example-rss) | A source in the library with search, and a row on the start page |

## Write your own

No compiler and no tools are needed: put a folder in Velouna's plugins folder, click **Reload**, look.

| Start here | |
|---|---|
| [Your first visualizer](docs/getting-started.md) | From an empty folder to a picture that moves with the music, in about fifteen minutes |
| [Your first Lua plugin](docs/lua-plugins.md#your-first-lua-plugin) | A plugin that reacts to the player, in two small files |
| [Testing and debugging](docs/testing.md) | Seeing changes right away, finding errors, keeping it smooth |

| Reference | |
|---|---|
| [plugin.json](docs/plugin-json.md) | Every field of the manifest |
| [Shaders](docs/shaders.md) | The inputs, helpers, passes and simulations of visualizers |
| [score.lua](docs/score-lua.md) | The Lua side of a visualizer |
| [Lua plugins](docs/lua-plugins.md) | Events, hooks, segments, menus, sources, network, storage, settings, permissions, limits |

All of it, with an overview: [docs/README.md](docs/README.md).

## Share your plugins

You don't need anyone's permission to publish a plugin. Anyone can run a repo, and anyone can add it to their Velouna with its link.

- [Your own repo](docs/repos.md): build a signed repo, put it on GitHub, let others add it by link.
- [Forking a plugin](docs/forking.md): build on someone else's plugin and publish it in your own repo.

A new example for this repo is welcome as a pull request that adds its folder under `plugins/` ([how](docs/README.md#contributing-an-example)).

## What is in here

```
plugins/<name>/                  plugin sources, one folder each
docs/                            documentation
repo.json, repo.json.sig         the signed index Velouna reads
packages/<id>/<id>-<version>.velounaplugin   built packages
```

`repo.json`, its signature and `packages/` are built from `plugins/`. Never edit them by hand: Velouna checks the signature and refuses a changed index. [What the signature does](docs/repos.md#what-the-signature-does-and-what-it-doesnt).

## License

All examples are MIT, so you can copy them into a plugin under any license. Each plugin names its license in its `plugin.json`.
