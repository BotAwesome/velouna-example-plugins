# Running your own plugin repo

A repo is a folder of static files: no server program and no account at Velouna. Put it anywhere that serves files over https, for example a GitHub repo. Others add it in Velouna with its link.

```
repo.json                         index of all plugins and versions
repo.json.sig                     signature of repo.json
packages/<id>/<id>-<version>.velounaplugin
packages/<id>/preview.webp        optional
```

## 1. Build it

**In Velouna (no tools needed):** go to **Settings → Extensions → Own repo** (Windows and Linux).

- **Plugins**: a folder with one subfolder per plugin, each with its `plugin.json`.
- **Repo folder**: where the repo is built. Use the same folder every time, so older versions stay listed.
- **Name** and **maintainer**: shown to people who add your repo.

**Build repo** packs every plugin, writes `repo.json` and signs it.

**With the command line tool** (when you build Velouna from source, `cargo build --release --bin velouna-repo`):

```
velouna-repo keygen my-repo.key
velouna-repo build plugins/ repo/ --key my-repo.key --name "My visualizers" --maintainer "Your name"
velouna-repo verify repo/
```

## 2. Keep the key safe

The first build creates a signing key. In Velouna it is `repo-signing.key` in Velouna's data folder (`%APPDATA%\Velouna` on Windows, `~/.config/Velouna` on Linux); the folder button next to **Key** on the **Own repo** page shows it. **Back it up.**

When someone adds your repo, Velouna remembers its key. Every later update must be signed with the same key. If the key changes, Velouna blocks all updates from the repo, like SSH does with a changed host key, and shows the old and the new fingerprint.

### If you lose the key

Build again with a new key, then **announce the change** where your users can find it, for example in your repo's README or on your website, with the new fingerprint (shown on the repo page in Velouna and by `velouna-repo verify`). Each user then chooses **Accept new key…** on your repo under **Settings → Extensions → Repos**, after comparing the fingerprint with your announcement. Their installed plugins stay linked to your repo.

Velouna can't tell a lost key from a repo someone else took over, so it never accepts a new key by itself, and it shows no button to skip the check during an update. The official repo can't be switched this way at all: its key is built into Velouna.

Never put the key file into the repo itself.

### What the signature does, and what it doesn't

The key is a pair. The **private key** is the key file: it stays on your computer, and only it can sign. The **public key** is written openly into `repo.json`. With it anyone can check a signature, but nobody can make one. That it is public is intended and safe.

When you build, `repo.json` is signed with your private key. The index lists every package with its size and SHA-256, so the signature covers all plugins in the repo. Velouna checks it with the public key it remembered when the repo was added. If anyone changes the index or a package, for example after taking over the GitHub account or the web space, the check fails and Velouna refuses the repo.

The signature says who publishes a repo. It is not copy protection: packages are plain zip files, and what others may do with a plugin is up to its license. Anyone can fork a plugin into their own repo with their own key (see [Forking a plugin](forking.md)). They just can't publish into yours.

## 3. Put it online

**GitHub:** make a repository, put the repo folder's contents at its top level (next to your plugin sources if you like) and push. The link to share is just the repository's address:

```
https://github.com/yourname/your-repo
```

Velouna reads `repo.json` from the default branch (`raw.githubusercontent.com/yourname/your-repo/HEAD/repo.json`).

On Windows, Git may change line endings on commit or checkout, which breaks the signature. Add a `.gitattributes` file to the repo with:

```
repo.json -text
repo.json.sig -text
*.velounaplugin binary
```

**Any web space:** upload the folder and share the address of the folder or of `repo.json`. It must be https.

## 4. Others add it

In Velouna: **Settings → Extensions → Repos → Add repo…**, paste the link, **Next**. Velouna shows the repo's name, maintainer and key fingerprint, and lists its plugins with a tick box each. People pick which ones to install right away. The rest stay in the **Catalog**.

### Linking a single plugin

To share just one plugin, link its folder instead of the repo:

```
https://github.com/yourname/your-repo/tree/main/plugins/neon-bars
```

Velouna reads the `plugin.json` in that folder, finds the `repo.json` in the nearest folder above it, and adds the repo with only that plugin. The catalog then shows only that plugin, and updates come as usual. Linking more plugins of the same repo adds them to it. **Show whole repo** in the repo's menu shows all of them.

This works for any web space, as long as the plugin folder with its `plugin.json` is reachable next to the repo, as in the layout above.

## Updates

Raise the plugin's `version`, build again into the same repo folder, push. Velouna checks the repos when the **Catalog** or **Repos** tab is opened, lists updates per repo under **Repos** and offers each on the plugin's row in **Installed**. An update is never installed silently: the permission dialog comes every time, and new permissions are marked.

A plugin only gets updates from the repo it was installed from.

## What Velouna checks

- `repo.json` must be signed by the repo's key. Once the repo is added, that key must not change, unless the user accepts a new one.
- Every package must match the size and SHA-256 in `repo.json`.
- The permissions in `repo.json` must match the ones in the package's `plugin.json`.
- Package paths stay inside the repo folder. Packages may not hold paths that leave the plugin's folder.
- Only https, except `http://localhost` and `http://127.0.0.1` for testing.
