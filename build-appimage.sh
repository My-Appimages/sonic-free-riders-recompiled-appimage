#!/usr/bin/env bash

source ./config.sh

version=""

while (($#)); do
  case "$1" in
    --version|-v)
      if [[ -z "${2:-}" ]]; then
        echo "ERROR: --version requires a version number." >&2
        exit 1
      fi
      version="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--version VERSION]"
      echo "  --version, -v  Download a specific release tag"
      echo "  --help, -h     Show this help"
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

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
  local asset_url
  local extracted_dir
  local api_url
  local release_json

  if [[ -n "$version" ]]; then
    api_url="https://api.github.com/repos/YuutaTsubasa/Free-Riders-Recompiled/releases/tags/$version"
    echo "Downloading Free Riders Recompiled version: $version"
  else
    api_url="https://api.github.com/repos/YuutaTsubasa/Free-Riders-Recompiled/releases/latest"
    echo "Downloading latest Linux x86-64 binary..."
  fi

  # Fetch release metadata.
  release_json="$(curl -fsSL "$api_url")" || {
    echo "ERROR: Failed to fetch release metadata: $api_url" >&2
    return 1
  }

  # Find the Linux x64 archive URL.
  asset_url="$(
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
    ' <<< "$release_json"
  )" || {
    echo "ERROR: Could not find the expected Linux x64 archive." >&2
    jq -r '.tag_name, (.assets[]?.name)' <<< "$release_json" >&2
    return 1
  }

  echo "Downloading archive: $asset_url"
  curl -fL --retry 3 "$asset_url" -o "$archive"

  # Start with a clean build directory.
  rm -rf build
  mkdir -p build
  tar -xzf "$archive" -C build

  extracted_dir="$(find build -type f -name FreeRidersRecompiled -printf '%h\n' -quit)"

  if [[ -z "$extracted_dir" ]]; then
    echo "ERROR: Could not find FreeRidersRecompiled in the archive." >&2
    find build -maxdepth 3 -print >&2
    return 1
  fi

  echo "Found game directory: $extracted_dir"

  if [[ "$extracted_dir" != "build" ]]; then
    cp -a "$extracted_dir"/. build/
  fi

  cp SFRR-launcher.sh build/
  chmod +x build/FreeRidersRecompiled build/SFRR-launcher.sh
}


build() {
  local libsdl2_path

  [[ -f "$desktop_file_path" ]] || {
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

  [[ -f "$appdir/usr/share/applications/SFRR.desktop" ]] || {
    find "$appdir" -iname '*.desktop' -print
    return 1
  }
}

package() {
  LDAI_OUTPUT="$appimage_filename" \
    linuxdeploy \
      --appdir "$appdir" \
      --output appimage

  chmod +x "$appimage_filename"
}

prepare_binary
build
package
