# hk-tui

Terminal client for Chromecast speakers, made for a Harman Kardon Citation but works with any Cast device (Nest, Google Home, …). Browse the albums in your music folder with fzf and vim keys, play an album or from a track, and see "now playing" in the footer.

Unofficial; not affiliated with Google or Harman Kardon.

## Install

### Arch Linux

**Prerequisites:** `git` and `base-devel` (for `makepkg`). The other dependencies (`fzf`, `curl`, `iproute2`, `python-pychromecast`) are installed by `makepkg`.

```bash
sudo pacman -S --needed git base-devel
git clone https://github.com/sukkergris/hk-tui.git ~/Code/hk-tui
cd ~/Code/hk-tui
./install.sh         # installs the dependencies, hk and hk-cast to /usr/bin
```

Update or reinstall: `~/Code/hk-tui/install.sh` (runs `git pull` and `makepkg -sif`; it builds what is pushed to GitHub, not local changes)
Development: `./dev.sh` copies the local `bin/hk` and `bin/hk-cast` to `/usr/bin`, uncommitted changes included (needs `sudo pacman -S python-pychromecast` once). Run `./install.sh` to go back to the packaged version.
Uninstall: `sudo pacman -R hk-tui-git`

### First run

```bash
hk scan               # Cast speakers on the network, e.g. "192.168.1.13 Living room"
hk use 192.168.1.13   # pick one (saved in the config)
hk                    # opens the UI
```

### Troubleshooting

- **"no answer from speaker at <IP>":** the speaker is off, or it got a new IP from DHCP. Run `hk scan` and `hk use <IP>`. To keep the IP fixed, reserve it in your router's DHCP. Use the MAC address the network actually sees: `ip neigh show <speaker IP>`.
- **"the player did not start":** see the log it names, `$XDG_RUNTIME_DIR/hk-<IP>.log`. Usually `python-pychromecast` is missing.
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
| `l` · `h` | albums ⇄ tracks |
| `gt` · `gT` | tabs: albums → tracks → speakers |
| `/` · `esc` | search · back |
| `enter` | play album / play from track · choose speaker |
| `space` · `n` · `p` · `+` · `-` | pause · next · previous · volume |
| `r` | speakers tab: scan the network |
| `?` · `q` | shortcuts · quit (playback continues) |

## Config

`~/.config/hk/config` (written by `hk use` and when you choose a speaker in the UI):

```bash
host=192.168.1.13   # speaker IP; reserve it in your router's DHCP
music=/home/you/Music
```

## How it works

- **Two parts:** `hk` (bash) is the UI and CLI. `hk-cast` (Python, pychromecast) is a small daemon per speaker that keeps the Cast connection, serves the queued files over HTTP and plays the queue track by track. `hk` starts it on demand and talks to it with curl over a unix socket (`$XDG_RUNTIME_DIR/hk-<IP>.sock`). Playback continues when you quit the UI; the daemon quits after 30 minutes without playback.
- **Files:** only the files in the current queue are served, so the music folder isn't open to the whole network.
- **Library:** every folder with audio files (mp3, flac, m4a, aac, ogg, opus, wav) is an album; track names are the file names.
- **Speakers:** found by asking every address on the /24 network for `http://<IP>:8008/setup/eureka_info`, which Cast devices answer with their name.
- **UI:** the script calls itself (`_enter`, `_key`, `_tracks`, `_preview`, `_now`, …) from fzf key bindings. State lives in `$XDG_RUNTIME_DIR/hk-ui-<pid>/`. A ticker updates the footer every second through fzf's `--listen` socket.

## License

MIT
