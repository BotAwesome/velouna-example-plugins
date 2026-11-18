# Velouna plugins

The official plugin repo of [Velouna](https://github.com/BotAwesome/velouna), the media player.
Velouna ships with this repo already added: open **Settings → Extensions → Catalog**, tick what you want and choose **Install selected**.

| Plugin | Kind | What it does |
|---|---|---|
| [Velounizer](plugins/velounizer) | Visualizer | Ink, Aurora and Contour: pictures that follow your music |
| [Example](plugins/example) | Visualizer | A plain, commented visualizer to learn from and copy |
| [Example: Bars](plugins/example-bars) | Visualizer | Eight bars from the music curves, no `score.lua` |
| [Example: Trails](plugins/example-trails) | Visualizer | Dots with trails: two passes and a feedback pass |
| [Example: Splash](plugins/example-splash) | Visualizer | Splashes on hits: a simulation driven by `step()` |
| [Example: Sections](plugins/example-sections) | Visualizer | Sun and moon that follow build-ups and drops: two presets, one shader |

To share one plugin of this repo without the others, link its folder, for example `https://github.com/BotAwesome/velouna-plugins/tree/main/plugins/example-bars`.

## Write your own plugin

A visualizer is a folder with a `plugin.json`, a GLSL shader and, if you like, a small Lua script. No compiler and no tools are needed: write it in Velouna's plugins folder, click **Reload**, look.

- **[Getting started](docs/getting-started.md)**: your first visualizer, step by step.
- [All documentation](docs/README.md): [plugin.json](docs/plugin-json.md), [shaders](docs/shaders.md), [score.lua](docs/score-lua.md), [testing](docs/testing.md).
- [Your own repo](docs/repos.md): build a signed repo, put it on GitHub, and let others add it by link.
- [Forking a plugin](docs/forking.md): build on someone else's plugin.

You don't need this repo to publish a plugin. Anyone can run a repo, and anyone can add it to their Velouna with its link.
To get a plugin into this official repo, open a pull request that adds its folder under `plugins/` ([rules](docs/README.md#contributing-to-the-official-repo)).

## What is in here

```
plugins/<name>/                  plugin sources, one folder each
docs/                            documentation
repo.json, repo.json.sig         the signed index Velouna reads
packages/<id>/<id>-<version>.velounaplugin   built packages
```

`repo.json`, its signature and `packages/` are built from `plugins/`. Never edit them by hand: Velouna checks the signature and refuses a changed index. [What the signature does](docs/repos.md#what-the-signature-does-and-what-it-doesnt).

## License

Each plugin names its license in its `plugin.json`. The Velounizer is GPL-3.0-or-later. The example is MIT, so you can copy it into a plugin under any license.
