# Forking a plugin

You may build on any plugin, as far as its license allows. The `license` in its `plugin.json` says what you may do. The examples are MIT: copy them into anything. The Velounizer is GPL-3.0-or-later: a fork must stay GPL and keep its source open, which a plugin folder always does.

Packages are plain zip files, not locked to anyone. The repo signature only says who publishes a repo, not who may use a plugin (see [What the signature does](repos.md#what-the-signature-does-and-what-it-doesnt)).

## How

1. Copy the plugin's folder. Get it from its repo's `plugins/` folder, or unzip its `.velounaplugin` package.
2. **Give it a new `id`**, for example `dev.yourname.velounizer`, and change `name` too, so people can tell the two apart.
3. Keep the original license and the author's notice, and add your name to `author`: `"BotAwesome, Your name"`.
4. Set `version` to where your fork starts, for example `1.0.0`.
5. Work on it as described in [Testing](testing.md), then publish it in your own repo ([Your own repo](repos.md)). Your repo gets its own key; you don't need anything from the original author.

## Why a new id

Velouna treats two plugins with the same `id` as the same plugin:

- Only one of them can be installed. Installing one replaces the other.
- Each gets updates only from the repo it was installed from, so users would lose track of which one they have.
- The user's settings for its presets (palette, seed, sliders) are stored by `id` and would be mixed up.

With a new `id`, both can be installed side by side.

## What a fork can't do

A fork can't publish into the original repo: that repo's `repo.json` is signed with its maintainer's key, and Velouna only accepts updates for it signed with that key. To get your changes into the original, send them to its maintainer, for example as a pull request on GitHub.
