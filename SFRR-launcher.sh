#!/usr/bin/env bash
set -Eeuo pipefail

HERE="$(cd -- "$(dirname -- "$(readlink -f -- "$0")")" && pwd)"

RUNTIME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/sonic-free-riders-recompiled"

mkdir -p "$RUNTIME_DIR"

rsync -a --exclude='/settings.ini' "$HERE/" "$RUNTIME_DIR/"

cd "$RUNTIME_DIR"
exec ./FreeRidersRecompiled "$@"
