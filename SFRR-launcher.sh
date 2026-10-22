#!/usr/bin/env bash
set -Eeuo pipefail

# Original, read-only AppImage directory.
HERE="$(cd -- "$(dirname -- "$(readlink -f -- "$0")")" && pwd)"

# Writable runtime copy and persistent user data.
BASE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/sonic-free-riders-recompiled"
GAME_DIR="$BASE_DIR/game"
DATA_DIR="$BASE_DIR/data"

mkdir -p "$GAME_DIR" "$DATA_DIR"

# Refresh the runtime copy of bundled files.
rsync -a --delete \
    --exclude='/settings.ini' \
    --exclude='/settings.ini.new' \
    --exclude='/save/' \
    "$HERE/" "$GAME_DIR/"

# Initialize settings only if the user doesn't have any yet.
if [[ ! -e "$DATA_DIR/settings.ini" && -f "$HERE/settings.ini" ]]; then
    cp "$HERE/settings.ini" "$DATA_DIR/settings.ini"
fi

# Redirect settings and save files to persistent storage.
rm -f "$GAME_DIR/settings.ini" "$GAME_DIR/settings.ini.new"
ln -s "$DATA_DIR/settings.ini" "$GAME_DIR/settings.ini"
mkdir -p "$DATA_DIR/save"
rm -rf "$GAME_DIR/save"
ln -s "$DATA_DIR/save" "$GAME_DIR/save"

cd "$GAME_DIR"
exec ./FreeRidersRecompiled "$@"
