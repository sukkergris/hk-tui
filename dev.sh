#!/usr/bin/env bash
# Developer install: copy the local bin/ (incl. uncommitted changes) over the installed files.
# Needs python-pychromecast (sudo pacman -S python-pychromecast). ./install.sh puts the packaged version back.
set -euo pipefail
cd "$(dirname "$0")"
sudo install -vDm755 bin/hk /usr/bin/hk
sudo install -vDm755 bin/hk-cast /usr/bin/hk-cast
