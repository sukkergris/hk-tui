# hk-tui

Terminal client for Chromecast speakers, made for a Harman Kardon Citation but works with any Cast device (Nest, Google Home, …). Browse the albums in your music folder with fzf and vim keys, play an album or from a track, and see "now playing" in the footer.

Unofficial; not affiliated with Google or Harman Kardon.

## Install

### Arch Linux

**Prerequisites:** `git` and `base-devel` (for `makepkg`). The other dependencies (`fzf`, `curl`, `ffmpeg`, `iproute2`, `python-pychromecast`) are installed by `makepkg`.

```bash
sudo pacman -S --needed git base-devel
git clone https://github.com/sukkergris/hk-tui.git ~/Code/hk-tui
cd ~/Code/hk-tui
./install.sh         # installs the dependencies, hk and hk-cast to /usr/bin
```

Update: `~/Code/hk-tui/install.sh`. It pulls the latest version from GitHub, builds the package and installs it with pacman. Restart the player daemon afterwards, so it runs the new code: `pkill -f hk-cast` (the next `hk` command starts it again; the song playing finishes, but the queue stops until then).
Uninstall: `sudo pacman -R hk-tui-git`
Changing the code? See [Development](#development).

### First run

```bash
hk scan               # Cast speakers on the network, e.g. "192.168.1.13 Living room"
hk use 192.168.1.13   # pick one (saved in the config)
hk                    # opens the UI
```

### Troubleshooting

- **"no answer from speaker at <IP>":** the speaker is off, or it got a new IP from DHCP. Run `hk scan` and `hk use <IP>`. To keep the IP fixed, reserve it in your router's DHCP. Use the MAC address the network actually sees: `ip neigh show <speaker IP>`.
- **"the player did not start":** see the log it names, `$XDG_RUNTIME_DIR/hk-<IP>.log`. Usually `python-pychromecast` is missing.
- **A red `! …` in the status line:** errors from the UI are logged in `$XDG_RUNTIME_DIR/hk-ui.log` (which call, line and command), together with when the UI started and exited; the newest is shown in the status line for 15 s.
- **An album in the wrong place:** the order comes from the tags of its first track (album artist, year, album). Fix the tags, then press `r` on the Music tab.
- **The speaker starts a track but plays nothing:** the speaker fetches the files from this computer over HTTP on a random port. A firewall must allow incoming connections from the LAN.
- **fzf error about unknown options (`--no-input`, `--footer`):** your fzf is older than 0.63.

## Usage

```bash
hk                 # UI
hk play PATH...    # play files or album folders (inside the music dir)
hk pause           # pause / resume
hk next|prev       # next / previous track
hk stop            # stop playback
hk vol [N|+N|-N]   # show or set volume (0–100)
hk status          # what is playing
hk scan            # Cast speakers on the local network
hk use <IP>        # switch speaker and save it in the config
```

| Key | Action |
|---|---|
| `j` · `k` · `ctrl-d` · `ctrl-u` · `gg` · `G` | move · half page · top / bottom |
| `l` · `h` | music ⇄ tracks |
| `gt` · `gT` | tabs: music → tracks → speakers |
| `gm` · `gS` | go to: music · speakers |
| `/` · `esc` | search · back |
| `tab` | search by album → artist → track (all tracks) |
| `enter` | play album / play from track · choose speaker |
| `space` · `n` · `p` · `+` · `-` | pause · next · previous · volume |
| `r` | music: read changed folders again · speakers: scan the network |
| `?` · `q` | shortcuts · quit (playback continues) |

`/` searches the album list; `tab` switches what it searches, like in bluos: **album** names, **artist** names, or **track** titles (a list of all tracks, `Title ‒ Artist • Album`). `enter` on a track plays its album from that track.

## Config

`~/.config/hk/config` (written by `hk use` and when you choose a speaker in the UI):

```bash
host=192.168.1.13   # speaker IP; reserve it in your router's DHCP
music=/home/you/Music
```

## How it works

- **Two parts:** `hk` (bash) is the UI and CLI. `hk-cast` (Python, pychromecast) is a small daemon per speaker that keeps the Cast connection, serves the queued files over HTTP and plays the queue track by track. `hk` starts it on demand and talks to it with curl over a unix socket (`$XDG_RUNTIME_DIR/hk-<IP>.sock`). Playback continues when you quit the UI; the daemon quits after 30 minutes without playback.
- **Files:** only the files in the current queue are served, so the music folder isn't open to the whole network.
- **Library:** every folder with audio files (mp3, flac, m4a, aac, ogg, opus, wav) is an album, shown as `Artist ‒ Album (Year)` and sorted by artist, year and album. These come from the first track's tags (`album_artist` or `artist`, `date` or `year`, `album`) via `ffprobe`, and are cached in `~/.cache/hk/tags.tsv` per folder; only new or changed folders are read again (~60 ms each, so ~5 s for 85 albums the first time, then instant). Folders without tags come last. Track names are the file names.
- **Status line:** the line just above "now playing" shows what hk is waiting for, with a spinner, e.g. `⠹ Reading artists and years 23/85…` or `Scanning the network for speakers…`; and `! The player doesn't answer` if hk-cast is gone.
- **Speakers:** found by asking every address on the /24 network for `http://<IP>:8008/setup/eureka_info`, which Cast devices answer with their name.
- **UI:** the script calls itself (`_enter`, `_key`, `_tracks`, `_preview`, `_now`, …) from fzf key bindings. State lives in `$XDG_RUNTIME_DIR/hk-ui-<pid>/`. A ticker updates the footer every second through fzf's `--listen` socket.

## Development

Two scripts install the app. Users only need `install.sh`; `dev.sh` is for trying changes.

| Script | Installs | Use it when |
|---|---|---|
| `./install.sh` | the package built from what is **pushed to GitHub** (`git pull`, `makepkg -sf`, `pacman -U`). pacman owns the files, and `pacman -Q hk-tui-git` shows the version. | you use the app, and after you have pushed a change |
| `./dev.sh` | your **working copy**: copies `bin/hk` and `bin/hk-cast` straight to `/usr/bin` with `sudo install`, uncommitted changes included. Needs `sudo pacman -S python-pychromecast` once. | you want to try a change before committing it |

A typical change:

1. Edit `bin/hk` and `bin/hk-cast`.
2. Try it: run `bin/hk` from the repo (nothing installed), or `./dev.sh` to have it as `hk` everywhere.
3. Commit and push.
4. `./install.sh` puts the packaged version back. It takes over the files `dev.sh` copied (`pacman -U --overwrite`); without that, pacman refuses with "exists in filesystem".

Good to know:

- `makepkg` writes the new `pkgver` (e.g. `r6.cce9dd8`) into `PKGBUILD`. Commit it as `chore: opdater pkgver fra makepkg`.
- After `./dev.sh`, `pacman -Qkk hk-tui-git` reports the files as modified. That is expected until the next `./install.sh`.
- Version bump: change `app="hk X.Y.Z"` in `bin/hk`, commit, add an annotated tag `vX.Y.Z` and push with `git push --follow-tags`.
- **Restart the daemon** after `./dev.sh` or `./install.sh`: `pkill -f hk-cast`. A running `hk-cast` keeps the old code until it quits.
- **Test runs talk to the real daemon.** There is one daemon per speaker, found by its socket (`$XDG_RUNTIME_DIR/hk-<IP>.sock`), so `bin/hk` from the repo controls the same queue as the installed one. Check `hk status` before testing, and use another config (`XDG_CONFIG_HOME=/tmp/test-config`) with a speaker nobody listens to.

## License

MIT
