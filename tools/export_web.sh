#!/usr/bin/env bash
# Exports the Godot project in $1 for the web into $2, stamped with version $3.
# The pack gets a unique name so GitHub Pages' 10 minute cache never serves
# stale game data to the phone. The files in web/ (manifest, icons, service
# worker) make it an installable web app that also runs offline.
set -euo pipefail
src="$1"; out="$2"; version="$3"

sed -i "s/^config\/version=.*/config\/version=\"${version}\"/" "$src/project.godot"
mkdir -p "$out"
log="$(mktemp)"
godot --headless --path "$src" --import > "$log" 2>&1 || true
if ! godot --headless --path "$src" --export-release "Web" "$(realpath "$out")/index.html" >> "$log" 2>&1 \
    || ! test -s "$out/index.pck"; then
  cat "$log"
  echo "Web export failed" >&2
  exit 1
fi
# Missing or broken scripts/resources would give a game that does not start.
if grep -E "SCRIPT ERROR|Parse Error|Failed loading resource" "$log"; then
  echo "Errors during the web export" >&2
  exit 1
fi

pck="index-${version//[^a-zA-Z0-9]/-}.pck"
mv "$out/index.pck" "$out/$pck"
sed -i "s/\"executable\":\"index\"/\"executable\":\"index\",\"mainPack\":\"$pck\"/; s/\"index.pck\":/\"$pck\":/" "$out/index.html"
grep -q "\"mainPack\":\"$pck\"" "$out/index.html"

# Older branches (previews) have no web/ yet: they stay a plain web page.
if [ -f "$src/web/sw.js" ]; then
  cp "$src"/web/manifest.webmanifest "$src"/web/sw.js "$src"/web/icon-*.png "$out/"
  files=$(cd "$out" && ls | grep -v '^sw\.js$' | sed 's/.*/"&"/' | paste -sd, -)
  sed -i "s/__VERSION__/${version}/; s/__FILES__/[${files}]/" "$out/sw.js"
  grep -q 'rel="manifest"' "$out/index.html"
fi
