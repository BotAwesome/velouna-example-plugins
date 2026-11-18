# Lua plugins

Lua plugins react to what the player does, add menu entries, buttons and dialogs, change what plays, and bring their own sources into the library. They are plugin interface version 2 (`"api": 2`) and need Velouna 0.4.0 or newer.

Velouna builds the framework; the plugins come from you. Scrobblers, SponsorBlock, podcast sources, home automation: everything on this page is there so that such plugins can be written with this documentation alone.

- [Your first Lua plugin](#your-first-lua-plugin)
- [plugin.json for Lua plugins](#pluginjson-for-lua-plugins)
- [How a plugin runs](#how-a-plugin-runs)
- [Events](#events) · [Hooks](#hooks) · [Segments](#segments)
- [The player](#the-player) · [Menus, buttons, dialogs](#menus-buttons-dialogs) · [Sources](#sources) · [The start page](#the-start-page)
- [Network](#network) · [Storage, settings, files](#storage-settings-files) · [Timers](#timers) · [Helpers](#helpers) · [Modules](#modules) · [Messages between plugins](#messages-between-plugins)
- [Permissions](#permissions) · [Limits](#limits) · [Testing](#testing) · [What is not there yet](#what-is-not-there-yet)

## Your first Lua plugin

Make a folder in Velouna's plugins folder (see [Testing](testing.md#the-loop)) with two files.

`plugin.json`:

```json
{
  "id": "dev.yourname.hello",
  "name": "Hello",
  "version": "1.0.0",
  "api": 2,
  "velouna": ">=0.4.0",
  "main": "main.lua",
  "provides": ["service"],
  "permissions": []
}
```

`main.lua`:

```lua
velouna.events.on("track-started", function(t)
  print("Now playing: " .. t.title)
  velouna.ui.toast("Hello, " .. t.title)
end)
```

In **Settings → Extensions → Installed** click **Reload** and switch *Hello* on. Play something: a small card says hello, and **⋯ → Console…** shows the line from `print`.

The examples in this repo each show one part of the interface. All are MIT, copy what you need:

| Example | Shows |
|---|---|
| [`example-log`](../plugins/example-log) | Events, the console, `velouna.storage` |
| [`example-webhook`](../plugins/example-webhook) | `velouna.http`, settings with an action button, `network:local` |
| [`example-segments`](../plugins/example-segments) | The `segments` hook: skip, ask, mute, mark, chapter |
| [`example-notes`](../plugins/example-notes) | Menu entries, dialogs, a player button, toasts |
| [`example-effects`](../plugins/example-effects) | A video shader, an audio filter, `velouna.timer` |
| [`example-clean-titles`](../plugins/example-clean-titles) | The `track-info` hook |
| [`example-module`](../plugins/example-module) | A module other plugins load with `require` |
| [`example-rss`](../plugins/example-rss) | A source with two levels, search, a start page row, `velouna.text.xml`, `requires` |

## plugin.json for Lua plugins

The fields of [plugin.json](plugin-json.md) (`id`, `name`, `description`, `version`, `velouna`, `author`, `license`, `permissions`) work as for visualizers. New:

| Field | Meaning |
|---|---|
| `api` | `2` |
| `kind` | Leave it out (or `"lua"`). |
| `main` | The Lua file Velouna runs first. Default `main.lua`. |
| `provides` | What the plugin offers: `service`, `menu`, `player-button`, `source`, `home`, `hooks`, `video-shader`, `audio-filter`, `module`. Shown to users; a plugin that only provides `module` is never started on its own. |
| `activate` | When it starts. `on:start-idle` (default): shortly after Velouna's window is up. `on:<event>`: only when that event first happens, e.g. `on:track-started`. Plugins with menus, buttons, sources or hooks should start at idle, or their entries are missing until then. |
| `requires` | Modules it loads: `[{ "id": "dev.someone.oauth", "version": ">=1.2" }]`. Velouna refuses to start it while one is missing. |
| `settings` | Its settings page, see [Settings](#settings). |
| `platforms` | Systems it runs on: `windows`, `linux`, `android`. Leave it out for all. A plugin that asks for `process` or `ipc:*` is desktop only, whatever this says. Velouna does not install a plugin for another system. |
| `devices` | What it is made for: `desktop`, `phone`, `tablet`. Leave it out for all. Velouna still runs it elsewhere, but marks it *Made for other devices*. |

## How a plugin runs

- Each plugin has its own Lua 5.4 and its own thread. Velouna sends it events as messages and never waits for it, except in [hooks](#hooks), and there only for a few milliseconds.
- `main.lua` runs once at start. Register handlers there; code at the top level runs before anything else happens.
- A handler runs to its end before the next message is handled. A `velouna.http` call waits for the answer, but only this plugin waits: Velouna and other plugins go on. Meanwhile, events for this plugin queue up.
- Every call into the plugin (an event, a hook, a menu entry …) gets a fresh copy of its arguments. Changing them changes nothing outside. Keep state in Lua variables of your file or in `velouna.storage`.
- An error in a handler is written to the console, the plugin keeps running. After 20 errors within a minute Velouna stops it.

The sandbox has Lua's `string`, `table`, `math`, `utf8`, `coroutine`, and `os.time`, `os.clock`, `os.date`, `os.difftime`. There is no `io`, no `os.execute`, no `load`, no `debug`, no `package`. `require` loads Lua files of the plugin itself and [modules](#modules). `print(...)` writes to the console.

## Events

```lua
velouna.events.on("track-started", function(t) ... end)
```

| Event | Arguments | When |
|---|---|---|
| `app-idle` | – | Once, when the plugins have been started |
| `track-started` | `t` | A file or stream starts (after [`track-info`](#hooks)) |
| `track-progress` | `t, position` | At most once a second while it plays |
| `paused`, `resumed` | `t, position` | |
| `seeked` | `t, position` | After a jump, once playback runs again |
| `track-ended` | `t, info` | `info.reason`: `eof` (to the end), `stop`, `error`, `other`; `info.position`, `info.played` (seconds really played) |
| `queue-changed` | `{ count, position }` | The queue changed |
| `settings-changed` | – | The user changed the plugin's settings |
| `message` | `from, msg` | Another plugin sent a message ([below](#messages-between-plugins)) |
| `app-quit` | – | Velouna closes. Plugins get one second together. |

The item `t`:

| Field | |
|---|---|
| `title`, `artist`, `album` | From the tags, or the file name; `artist` and `album` may be missing |
| `duration` | Seconds, 0 when not known (live streams) |
| `kind` | `audio` or `video` |
| `source` | `file`, `stream`, `radio`, `tv`, `plex`, `jellyfin`, `emby`, `plugin` |
| `path` | The file or URL. Empty for media servers: their addresses and sign-ins stay private. |
| `url` | For streams |
| `youtube_id` | For YouTube links and files named like yt-dlp names them (`Title [id].mp4`) |
| `plugin`, `id`, `item` | For media from a plugin source: the plugin, the item's `id` and the whole item |

A scrobbler, roughly:

```lua
local scrobbled = {}

velouna.events.on("track-started", function(t)
  scrobbled[t.path] = nil
  if t.kind == "audio" then send_now_playing(t) end
end)

velouna.events.on("track-progress", function(t, pos)
  if t.kind == "audio" and not scrobbled[t.path] and t.duration > 30 and pos >= math.min(t.duration / 2, 240) then
    scrobbled[t.path] = true
    scrobble(t, os.time() - math.floor(pos))
  end
end)
```

## Hooks

Events tell what happened. Hooks run before something happens and may change it. One handler per hook and plugin:

```lua
velouna.hooks.on("track-info", function(t)
  return { title = t.title:gsub(" %(Official Video%)", "") }
end)
```

Return a table with the fields to change, or `nil` for no change. When several plugins have the same hook, they run one after another in the order of the plugin list; each sees what the one before returned.

| Hook | Runs | May return | Budget | Network | Permission |
|---|---|---|---|---|---|
| `track-info(t)` | before `track-started` | `title`, `artist`, `album` | 50 ms | no | – |
| `segments(t)` | when a file starts, in the background | a list of [segments](#segments) | none | yes | – |
| `before-play(item)` | before mpv opens a file or URL | `url`, `headers`, `start`, `title`, `audio_lang`, `sub_lang`, `ytdl_format`, or `cancel = "reason"` | 30 ms | no | `hooks:play` |
| `play-failed(item)` | when mpv could not open it | `url` (and `headers`) to try instead, or `message` | 3 s | yes | `hooks:play` |
| `live-info(t)` | the title of a radio stream changes (`t.live_title`) | `action = "mute"` or `"quiet"` until the next title, nothing to restore | 50 ms | no | – |

`before-play` and `play-failed` get `{ url, path, youtube_id, error, plugin, item }`. A new `url` must be on a host the plugin may reach.

**Budgets.** A hook that takes longer than its budget is passed over for this call; Velouna does not wait. After five overruns Velouna switches the hook off for this session and says so in the console. "No network" means `velouna.http` raises an error in that hook: fetch what you need earlier (in a service or in `segments`) and keep it.

**The first file stays fast.** Plugins start shortly after Velouna's window is up. The file Velouna was opened with plays without waiting for any hook; `before-play` applies from the next file on. `track-info` and `segments` still run for it once the plugins are loaded.

Media servers (Plex, Jellyfin, Emby) never pass through `before-play` or `play-failed`: their stream addresses carry sign-in data.

## Segments

The `segments` hook returns parts of the file:

```lua
velouna.hooks.on("segments", function(t)
  if not t.youtube_id then return nil end
  local list = fetch_from_my_service(t.youtube_id)   -- may use the network
  local out = {}
  for _, s in ipairs(list) do
    out[#out + 1] = { from = s.start, to = s["end"], action = "skip", label = s.category }
  end
  return out
end)
```

| Field | |
|---|---|
| `from`, `to` | Seconds (also `start`, `stop`) |
| `action` | `skip`: jumped over, with an *Undo* card. `ask`: a *Skip* button while inside. `mute`: sound off while inside. `mark`: only shown on the seek bar. `chapter`: a chapter mark at `from`. |
| `label` | Shown on the seek bar's hover card and on the cards |
| `color` | `"#rrggbb"`, otherwise one per action |

Segments show on the seek bar right away. A `skip` segment is skipped once each time playback enters it; after *Undo*, or once the user seeks back in front of it, it counts again.

For SponsorBlock, ask its API by hash prefix (`/api/skipSegments/<first 4 characters of sha256(video id)>`, then pick your video from the answer): the server never learns which video plays. `velouna.hash.sha256` is there for that.

## The player

```lua
local st = velouna.player.state()
-- st.time, st.duration, st.paused, st.volume, st.muted, st.speed, st.idle,
-- st.title, st.path, st.playlist_pos, st.playlist_count

local t = velouna.player.current()   -- the item playing now, or nil
```

| Function | |
|---|---|
| `play()`, `pause()`, `toggle()`, `stop()`, `next()`, `prev()` | |
| `seek(seconds)`, `seek_by(seconds)` | |
| `set_volume(0–130)`, `set_mute(bool)`, `set_speed(0.1–8)` | |
| `load(url, { mode, title, start })` | `mode`: `replace` (default), `append`, `next`. The host must be allowed (see [Network](#network)); local files need `files:read`. |
| `add_subtitle(x)` | `x`: a URL, a file in the plugin's [files](#storage-settings-files), or `{ text = "…", format = "srt", name = "English" }` (`srt`, `vtt`, `ass`, `ssa`, `lrc`) |
| `video_shader(file)` | An [mpv user shader](https://mpv.io/manual/master/#options-glsl-shaders) from the plugin folder (`.glsl`/`.hook`) on the picture; `nil` takes it off |
| `audio_filter(chain)` | FFmpeg audio filters, `nil` removes them: `"equalizer=f=100:g=4,dynaudnorm"`. Allowed: `equalizer bass treble lowshelf highshelf highpass lowpass bandpass bandreject allpass acompressor dynaudnorm loudnorm volume alimiter compand agate aecho chorus flanger vibrato tremolo extrastereo stereotools stereowiden crystalizer earwax haas pan superequalizer firequalizer speechnorm deesser aphaser`. No filter graphs, no quotes. |
| `add_button{ id, icon, label, run }` | A button in the player bar; `run(t)` on click. `remove_button(id)`. |

Shader and filter stay until the plugin changes them or is switched off.

`velouna.media.sidecar(ext)` reads a small text file next to the local file that plays: `sidecar("lrc")` reads `Song.lrc` for `Song.mp3`. Allowed: `lrc srt vtt ass txt json nfo cue xml segments.json chapters.txt edl md`, at most 2 MB. No permission needed; returns `nil` if there is none.

## Menus, buttons, dialogs

```lua
velouna.menu.add({
  id = "love",
  label = { en = "Love on My Service", de = "Auf My Service lieben" },
  icon = "heart",
  where = { "player", "main" },
  kinds = { "audio" },                -- optional: only for these item kinds
  run = function(t) love(t) end,
})
velouna.menu.remove("love")
```

| `where` | Menu | `run` gets |
|---|---|---|
| `player` | Right click on the picture | the item playing |
| `main` | The ☰ menu | the item playing (or nil) |
| `item` | Right click on an entry of a plugin source | that entry |

`label` is a string or one per language (`en`, `de`, …). Icon names: `heart star bookmark share music microphone podcast moon sparkle lightning chat info download plus check flag bell globe thumbs-up thumbs-down list eye timer rss radio tv film folder cloud book game skip subtitles lyrics chart user home magic palette search`. Others show a puzzle piece.

**Toasts** – `velouna.ui.toast("Saved")`: a card for four seconds.

**Dialogs:**

```lua
velouna.ui.dialog({
  title = "Sign in",
  text = "Your account at My Service",
  fields = {
    { id = "user", type = "text", label = "User name" },
    { id = "pass", type = "password", label = "Password" },
    { id = "remember", type = "toggle", label = "Stay signed in", default = true },
    { id = "quality", type = "choice", label = "Quality", options = { "low", { value = "high", label = "High" } }, default = "high" },
    { id = "limit", type = "number", label = "Items", default = 20 },
  },
  buttons = { { id = "cancel", label = "Cancel" }, { id = "ok", label = "Sign in", primary = true } },
}, function(button, values)
  if button == "ok" then sign_in(values.user, values.pass) end
end)
```

The callback gets the button's `id` (`"close"` if the dialog was closed otherwise) and the field values. Without `buttons` there is one *OK*. Don't keep passwords: trade them for a token and store that as a [secret](#settings).

**Progress:**

```lua
velouna.ui.progress("sync", { text = "Syncing 3 of 10", value = 0.3, on_cancel = function() stop = true end })
velouna.ui.progress("sync", { done = true })
```

`value` 0–1, or leave it out for "busy". `on_cancel` adds an ✕ button.

## Sources

A source appears in the library's sidebar (on phones under *More*):

```lua
velouna.sources.add({
  id = "podcasts",
  label = "Podcasts",
  icon = "microphone",
  browse = function(path)              -- "" is the source's start page
    if path == "" then
      return velouna.ui.list({ items = my_feeds(), view = "grid" })
    end
    return velouna.ui.list({ items = episodes(path), view = "list" })
  end,
  resolve = function(item)             -- optional: only when an item has no url
    return { url = fresh_link(item.id), headers = { Authorization = "…" } }
  end,
  search = function(text)              -- optional: adds a search field
    return find(text)
  end,
})
```

`browse` returns a list of items, or `velouna.ui.list({ items = …, view = "list" | "grid" })`. Opening an item without `url` and without `playable = true` opens `browse(item.id)`, with breadcrumbs back. Pages are kept until the user clicks *Reload*.

An item:

```lua
{
  id = "feed:123/ep:45",         -- stable: a folder's id is the path browse() gets
  kind = "episode",              -- folder, audio, track, video, movie, episode, stream, picture
  title = "…", subtitle = "…", description = "…",
  art = { thumb = url, poster = url },
  duration = 1834,
  url = "https://…",             -- plays right away; or playable = true and resolve()
  playable = true,
  data = { … },                  -- yours, comes back in resolve(item)
}
```

`resolve` returns a URL or `{ url, title, headers, start }`. Playback URLs and images must be on hosts the plugin may reach. Video items switch to the player; audio, episodes and streams play on with the mini player.

## The start page

```lua
velouna.home.add({
  id = "new",
  label = { en = "New episodes", de = "Neue Folgen" },
  items = function() return newest_items() end,
})
```

A row of tiles on the start page. `items` is called once per session (and again when it failed). Clicking a playable item plays it, a folder opens the plugin's first source at that item.

## Network

```lua
local res, err = velouna.http.get("https://api.example.com/v1/items", { headers = { Accept = "application/json" } })
if not res then velouna.warn(err) return end
if res.ok then
  local data = velouna.json.decode(res.body)
end
```

| Function | |
|---|---|
| `http.get(url, opts)` | |
| `http.post(url, body, opts)` | `body`: a string, or a table sent as JSON |
| `http.request(opts)` | `url`, `method` (`GET POST PUT PATCH DELETE HEAD`), `headers`, `body` or `json`, `query` (a table, added to the URL), `timeout` (seconds, 1–60, default 20) |

The answer: `status`, `ok` (2xx), `headers` (lower-case names), `body` (string, at most 16 MB), `url` (after redirects). On a network error: `nil` and a message.

Every request, also each redirect, is checked against the plugin's `network:` permissions in Velouna, not in Lua:

| Permission | Allows |
|---|---|
| `network:api.example.com` | that host |
| `network:*.example.com` | `example.com` and every subdomain |
| `network:local` | the home network and this device (`192.168.*`, `10.*`, `*.local`, `localhost` …) |
| `network:*` | every public host (users see a strong warning) |

A request to another host raises an error that names the permission to add. There is no other way into the network: no sockets, no `io.popen`. Velouna sends `User-Agent: Velouna/<version> (plugin <id>)`.

## Storage, settings, files

**Storage** – the plugin's own data, kept across restarts (up to 8 MB in all):

```lua
velouna.storage.set("token_expires", os.time() + 3600)
local n = velouna.storage.get("plays") or 0
velouna.storage.remove("old")
local keys = velouna.storage.keys()
```

Values are anything JSON can hold.

### Settings

Declared in `plugin.json`, drawn by Velouna under **⋯ → Settings…**:

```json
"settings": [
  { "id": "user", "type": "text", "label": "User name" },
  { "id": "token", "type": "secret", "label": "API key" },
  { "id": "music_only", "type": "toggle", "label": "Music only", "default": true },
  { "id": "percent", "type": "slider", "label": "Scrobble at (%)", "min": 30, "max": 90, "step": 5, "default": 50 },
  { "id": "quality", "type": "choice", "label": "Quality", "options": ["low", {"value": "high", "label": {"en": "High", "de": "Hoch"}}], "default": "high" },
  { "id": "sources", "type": "multi", "label": "Count", "options": ["file", "plex", "radio"], "default": ["file"] },
  { "id": "connect", "type": "action", "label": "Connect", "run": "connect" },
  { "id": "folder", "type": "folder", "label": "Folder" }
]
```

`label` and `help` take a string or one per language. In Lua:

```lua
local p = velouna.settings.get("percent")
velouna.settings.set("user", "someone")       -- e.g. after signing in
velouna.settings.on_action("connect", function() start_sign_in() end)
velouna.events.on("settings-changed", function() reload_config() end)
```

`secret` values live in the system's keychain (Windows Credential Manager, the Secret Service on Linux, app-private storage on Android), never in Velouna's config file. `settings.set` on a secret stores it there, `settings.set(id, nil)` deletes it. `folder` stores a path the user picked (desktop only); reading files in it is not available yet.

**Files** – the plugin's own files folder (`plugin-data/<id>/files/`), for caches and downloads:

```lua
velouna.files.write("cache/feed.xml", body)
local text = velouna.files.read("cache/feed.xml")     -- nil if missing
local names = velouna.files.list("cache")
velouna.files.remove("cache/feed.xml")
```

Paths are relative; `..` and absolute paths are refused. Removing a plugin asks whether to keep this data.

## Timers

```lua
local id = velouna.timer.every(60, function() check_feeds() end)
velouna.timer.after(5, function() velouna.ui.toast("five seconds later") end)
velouna.timer.cancel(id)
```

Timers run while Velouna runs, also with the window in the background. `every` runs at most ten times a second.

## Helpers

| | |
|---|---|
| `velouna.json.encode(v, pretty)`, `velouna.json.decode(s)` | `decode` returns `nil, error` for bad JSON |
| `velouna.base64.encode(s)`, `.encode_url(s)`, `.decode(s)` | |
| `velouna.hash.md5(s)`, `.sha1(s)`, `.sha256(s)` | Hex strings |
| `velouna.hash.hmac_sha1(key, msg)`, `.hmac_sha256(key, msg)` | Hex strings |
| `velouna.url.encode(s)`, `.decode(s)` | Percent-encoding |
| `velouna.url.query({ a = 1, b = "x y" })` | `"a=1&b=x%20y"`, sorted by name (for signatures) |
| `velouna.url.parse(u)` | `{ scheme, host, port, path, query, params }` |
| `velouna.text.xml(s)` | XML (RSS, Atom, APIs) as `{ name, attrs, text, children }`; `nil, error` if it can't be read |
| `velouna.text.strip_tags(html)`, `.unescape(s)`, `.trim(s)`, `.split(s, sep)` | |
| `velouna.text.time(s)` | `"1:02:03"` → 3723; RFC 3339 / RFC 2822 dates → Unix time |
| `velouna.uuid()`, `velouna.time()` | A random UUID; Unix time with fractions |
| `velouna.id`, `.version`, `.app_version`, `.api`, `.platform`, `.language` | |
| `velouna.log(...)`, `velouna.warn(...)`, `print(...)` | To the console |
| `velouna.open_url(url)` | Opens an http(s) link in the browser; needs `open-url` |

MD5 is there for APIs that still sign with it (Last.fm). Don't use it for anything new.

## Modules

A module is a plugin that only provides `module`. Its `main` file returns a table:

```lua
-- dev.someone.util / lib.lua
local M = {}
function M.duration(s) return string.format("%d:%02d", s // 60, s % 60) end
return M
```

Another plugin names it in `requires` and loads it:

```lua
local util = require("dev.someone.util")
```

A module runs inside the plugin that loads it, with that plugin's permissions: a module can't do more than its user. `require("lib.parser")` (without a plugin id) loads `lib/parser.lua` from the plugin's own folder.

## Messages between plugins

```lua
velouna.plugins.send("dev.someone.other", { kind = "hello" })
velouna.plugins.on_message(function(from, msg) ... end)
```

A message only arrives if the receiving plugin runs and listens with `on_message`.

## Permissions

Without asking: own storage, settings and files, events, the item playing, controlling playback, menus, buttons, dialogs, toasts, sources, the start page, segments, `track-info`, `live-info`, video shaders and audio filters.

| Permission | Users read | Gives |
|---|---|---|
| `network:<host>`, `network:*.<domain>` | May connect to … | `velouna.http`, playing and showing images from that host |
| `network:local` | May talk to devices in your home network | The same, for the home network |
| `network:*` | May connect to any server (critical) | Every public host |
| `open-url` | May open links in the browser | `velouna.open_url` |
| `hooks:play` | May change what plays | `before-play`, `play-failed` |
| `files:read` | May read files in folders you choose | Playing local paths with `player.load` |

The install dialog lists every permission; a plugin from the plugins folder asks when it's switched on. Velouna checks permissions in Rust: a function the plugin has no right to raises an error.

These permissions are reserved for later (see [What is not there yet](#what-is-not-there-yet)) and marked *(no function yet)* when asked for: `hooks:stream`, `files:write`, `library`, `history`, `history:write`, `servers`, `clipboard`, `ipc:<name>`, `process`, `server`, `tags`, `cast`.

## Limits

| | |
|---|---|
| Computing time per call | 1 second (waiting for the network doesn't count) |
| Loading `main.lua` and modules | 3 seconds |
| Memory | 64 MB per plugin |
| Response body | 16 MB |
| Storage | 8 MB |
| Errors | 20 in a minute stop the plugin |
| Timers | 256 per plugin |

## Testing

Develop in the plugins folder as described in [Testing and debugging](testing.md). For Lua plugins:

- **⋯ → Console…** on the plugin shows everything it printed, its errors with file and line, and its costs: load time, calls, computing time, the longest call, requests and errors.
- The console's prompt runs Lua inside the running plugin: `velouna.player.state()`, `velouna.storage.keys()`, or call your own functions. An expression shows its value.
- **Restart** in the console loads the plugin again after you changed its files. **Reload** on the Installed tab restarts all plugins.
- `velouna --no-plugins` starts Velouna without any plugins.
- The console's lines also go to Velouna's log, starting with `plugin <id>:`.

## What is not there yet

The framework grows in steps. Not available in Velouna 0.4.0:

- the hooks `display`, `queue-add` and `hls-playlist`;
- providers for lyrics, art, subtitles and metadata, overlays, sync, cast, screensavers, themes and language packs as plugins;
- custom pages beyond item lists, playlist formats, `velouna://` links;
- reading folders the user picked (`files:read` beyond playing local paths), the library, history, server sign-ins, the clipboard, starting programs, a local server, device discovery, WebSockets and SQLite;
- remembering progress per plugin item `id` (progress is kept per URL, like for other streams);
- `velouna-plugin test`, a command-line runner without the window.

Functions are added without breaking plugins written for `"api": 2`.
