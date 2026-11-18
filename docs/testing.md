# Testing and debugging

## The loop

Work on a plugin inside Velouna's plugins folder:

| System | Plugins folder | Log |
|---|---|---|
| Windows | `%APPDATA%\Velouna\plugins\` | `%LOCALAPPDATA%\velouna\velouna.log` |
| Linux | `~/.config/Velouna/plugins/` | `~/.cache/velouna/velouna.log` |

Every folder in there with a `plugin.json` is a plugin, whatever the folder's name. Put your plugin's folder there (or, on Linux, a symlink to it), then in **Settings → Extensions → Installed** click **Reload** and switch the plugin on.

After that, the loop is: edit a file, save, click **Reload**. Reload reads all `plugin.json` files again, recompiles the shaders and runs `score.lua`'s `build` again. Keep a song paused at a good spot while you work: time stands still, and the picture redraws after each reload.

To find the folder from Velouna, choose **⋯ → Show in Explorer** (Linux: **Show in file manager**) on any installed plugin and go one folder up.

Reload is on Windows and Linux. On Android there's no plugins folder you can reach: test there by installing a package (see [below](#on-android)).

Lua plugins have a console of their own, with their log, their costs and a Lua prompt: see [Testing Lua plugins](lua-plugins.md#testing). The rest of this page is about visualizers.

## Where errors show up

| Where | What it means |
|---|---|
| **Installed** list, red: *Not loaded: …* | `plugin.json` is missing or broken, the `id` isn't valid, or the plugin needs a newer Velouna. The message names the problem, for JSON mistakes with line and column. |
| Player: *Visualizer stopped: …* | A shader didn't compile, a file is missing, or `score.lua` raised an error or ran over a limit. |
| The plugin isn't in the visualizer menu | It's switched off. |

Shader errors look like this:

```
draw.glsl: ERROR: 1:13: 'rgbx' : vector swizzle selectors not from the same set
```

`1:13` is line 13 of your file (the `1` in front is the file number). The wording and format depend on the graphics driver. Lua errors name the file and line, followed by the functions that were running:

```
runtime error: score.lua:15: attempt to index a nil value (local 'h')
stack traceback:
    [C]: in metamethod 'index'
    score.lua:15: in function 'frame'
```

After fixing the file, **Reload** clears the error and tries again.

## The log

`print(...)` in `score.lua` writes a line to Velouna's log, starting with `plugin:`. Velouna also logs how long each `build` took:

```
visualizer: pulse score built in 38 ms
```

The log is new each time Velouna starts. On Linux you can watch it with `tail -f ~/.cache/velouna/velouna.log`; on Windows, `Get-Content $env:LOCALAPPDATA\velouna\velouna.log -Wait` in PowerShell.

Don't `print` in `frame` or `step` without a limit: they run 60 times a second. Print once, for example only when `first` is true, or count calls.

## Checking with different songs

Analyses differ a lot between songs. Before publishing, try your presets with:

- a song with a hard four-on-the-floor kick,
- a quiet song with almost no hits (does it still move? does it look empty?),
- a long song (does anything pile up?),
- several seeds and every palette,
- the window narrow and tall, wide and short, and fullscreen.

Seek around. A `feedback` or `step` preset should look right a moment after a jump.

## Keeping it smooth

Visualizers draw every frame at up to 1920 pixels on the longer side. A preset should stay smooth on a mid-range laptop at 1080p.

- **Loops**: a loop over 16 rings is fine. A loop over 64 in every pixel of a full-size pass gets expensive. Do expensive work in a `scale: 0.5` pass and read it in the last pass.
- **Noise**: every `fbm` octave costs. Three or four octaves are usually enough.
- **Textures**: `tex_tl` on a small pass is cheap; dozens of taps per pixel are not.
- **Lua**: keep `frame` and `step` free of loops over the whole song. Plan in `build`, and remember where you are.

To see what a preset costs, compare its smoothness with Velouna's own Aurora preset on the same song and window.

## On Android

On a phone, test the way users will get the plugin: build a repo (see [Your own repo](repos.md)), put it online, add it in Velouna on the phone and install from the catalog. For quick checks, a repo served from your computer over `http://` doesn't work on the phone: Velouna accepts plain http only from the device itself.

Things that differ on phones:

- GLSL compilers on phones are stricter (see [Shaders](shaders.md#things-that-go-wrong)).
- Some phones can't draw into float targets: `rgba16f` passes fall back to `rgba8`.
- A phone runs fewer simulation steps per frame, so catching up after a seek takes a little longer.

## Building a package to test

To try the plugin the way others will install it, build a repo from it (**Settings → Extensions → Own repo**) and drag `packages/<id>/<id>-<version>.velounaplugin` from the repo folder into the Velouna window. Move your working copy out of the plugins folder first: Velouna installs the package into a folder named after the `id`, and two folders with the same `id` get in each other's way.

A published version must not change. While you're still testing packages, raise the version for each build, or delete the repo folder before building again.
