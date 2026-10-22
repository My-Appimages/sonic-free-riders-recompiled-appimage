
#!/usr/bin/env bash

# Config
icon_path="Icons/SFRR.png"
executable_path="build/FreeRidersRecompiled"
desktop_file_path="SFRR.desktop"
appimage_filename="Sonic-Free-Riders-Recompiled-x86_64.AppImage"
appdir="SFRR.AppDir"
release_name="FreeRidersRecompiled-0.10.21-linux-x64"
archive="FreeRidersRecompiled-linux-x64.tar.gz"

find_library() {
  local lib="$1"
  local path

  path="$(ldconfig -p | awk -v lib="$lib" '$1 == lib { print $NF; exit }')"

  if [[ -z "$path" || ! -e "$path" ]]; then
    echo "ERROR: Required library not found: $lib" >&2
    return 1
  fi

  printf '%s\n' "$path"
}

prepare_binary() {
  echo "Downloading latest Linux x86-64 binary..."

  local api_url="https://api.github.com/repos/YuutaTsubasa/Free-Riders-Recompiled/releases/latest"
  local asset_url
  local extracted_dir

  asset_url="$(
    curl -fsSL "$api_url" |
      jq -er '
        [
          .assets[]
          | select(.name | test("linux-x64\\.tar\\.gz$"; "i"))
        ]
        | if length == 1 then
            .[0].browser_download_url
          else
            error("Expected exactly one Linux x64 tar.gz asset")
          end
      '
  )"

  curl -fL --retry 3 "$asset_url" -o "$archive"

  # Inspect the archive before extracting it.
  tar -tzf "$archive" | head -n 30

  mkdir -p build
  tar -xzf "$archive" -C build

  # Find the actual extracted directory instead of assuming its name.
  extracted_dir="$(find build -type f -name FreeRidersRecompiled -printf '%h\n' | head -n 1)"

  if [[ -z "$extracted_dir" ]]; then
    echo "ERROR: Could not find FreeRidersRecompiled in the extracted archive." >&2
    find build -maxdepth 3 -print
    return 1
  fi

  echo "Found game directory: $extracted_dir"

  # Keep all files shipped with the game.
  cp -a "$extracted_dir"/. build/
  cp SFRR-launcher.sh build/
  chmod +x build/FreeRidersRecompiled build/SFRR-launcher.sh
}






build() {
  local libsdl2_path

  [[ -f "$desktop_file_path" ]] || {
    echo "ERROR: Desktop file missing: $desktop_file_path" >&2
    return 1
  }

  libsdl2_path="$(find_library libSDL2-2.0.so.0)"

  mkdir -p "$appdir/usr/bin"
  cp -a build/. "$appdir/usr/bin/"

  linuxdeploy \
    --appdir "$appdir" \
    --executable "$appdir/usr/bin/FreeRidersRecompiled" \
    -l "$libsdl2_path" \
    --desktop-file "$desktop_file_path" \
    --icon-file "$icon_path"

  # Ensure the desktop entry exists where AppImage tools expect it.
  [[ -f "$appdir/usr/share/applications/SFRR.desktop" ]] || {
    echo "ERROR: linuxdeploy did not install the desktop file." >&2
    find "$appdir" -iname '*.desktop' -print
    return 1
  }
}

package() {
  [[ -f "$appdir/usr/share/applications/SFRR.desktop" ]] || {
    echo "ERROR: Desktop file not found in AppDir." >&2
    return 1
  }

  LDAI_OUTPUT="$appimage_filename" \
    linuxdeploy \
      --appdir "$appdir" \
      --output appimage

  [[ -f "$appimage_filename" ]] || {
    echo "ERROR: AppImage was not created!" >&2
    return 1
  }

  chmod +x "$appimage_filename"
  echo "Built successfully: $appimage_filename"
}



prepare_binary
build
package
