#!/bin/sh
set -eu

site_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
diagram_dir=$site_dir/assets/diagrams

if ! command -v drawio >/dev/null 2>&1; then
  printf 'draw.io CLI not found. Install the desktop application first.\n' >&2
  exit 1
fi

if ! command -v magick >/dev/null 2>&1; then
  printf 'ImageMagick not found. Install it before exporting social images.\n' >&2
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

social_source=$diagram_dir/gpu-readiness-boundaries.drawio
social_output=$site_dir/static/images/writing/gpu-readiness-boundaries.png
social_raw=$(mktemp)
trap 'rm -f "$social_raw"' EXIT INT TERM

drawio \
  --export \
  --format png \
  --theme light \
  --width 1200 \
  --output "$social_raw" \
  "$social_source"

magick "$social_raw" \
  -resize 1120x \
  -background '#0B0E16' \
  -gravity center \
  -extent 1200x630 \
  "$social_output"
