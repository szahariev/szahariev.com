#!/bin/sh
set -eu

site_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
diagram_dir=$site_dir/assets/diagrams

if ! command -v drawio >/dev/null 2>&1; then
  printf 'draw.io CLI not found. Install the desktop application first.\n' >&2
  exit 1
fi

for source in "$diagram_dir"/*.drawio; do
  output=${source%.drawio}.svg
  drawio \
    --export \
    --format svg \
    --theme light \
    --transparent \
    --embed-svg-fonts false \
    --output "$output" \
    "$source"
  "$site_dir/scripts/prepare-diagram-svg.sh" "$output"
done
