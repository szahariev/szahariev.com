#!/bin/sh
set -eu

site_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT INT TERM

hugo --source "$site_dir" --destination "$build_dir" --gc --minify

required_paths="index.html writing/index.html speaking/index.html about/index.html feed.xml sitemap.xml 404.html bg/index.html bg/writing/index.html bg/speaking/index.html bg/about/index.html bg/feed.xml"
for path in $required_paths; do
  if [ ! -s "$build_dir/$path" ]; then
    printf 'Missing or empty output: %s\n' "$path" >&2
    exit 1
  fi
done

if rg -n 'href="(http://localhost|/Users/)' "$build_dir" >/dev/null; then
  printf 'Local path leaked into generated output.\n' >&2
  exit 1
fi

if ! rg -q '<html lang="?en-GB"?' "$build_dir/index.html" ||
   ! rg -q '<html lang="?bg-BG"?' "$build_dir/bg/index.html"; then
  printf 'Generated pages do not declare the expected language.\n' >&2
  exit 1
fi

if ! rg -q 'hreflang="?bg-BG"? href="?https://szahariev.com/bg/' "$build_dir/index.html" ||
   ! rg -q 'hreflang="?en-GB"? href="?https://szahariev.com/' "$build_dir/bg/index.html"; then
  printf 'Language alternates are missing from generated home pages.\n' >&2
  exit 1
fi

if ! rg -q 'data-theme-toggle' "$build_dir/index.html"; then
  printf 'Theme control is missing from generated output.\n' >&2
  exit 1
fi

if rg -n '[‘’‚‛“”„‟«»‹›]' \
  "$site_dir/content" \
  "$site_dir/i18n" \
  "$site_dir/layouts" \
  "$site_dir/hugo.yaml" >/dev/null; then
  printf 'Use straight ASCII apostrophes and quotation marks in site copy.\n' >&2
  exit 1
fi

for diagram in "$site_dir"/assets/diagrams/*.svg; do
  if ! rg -q '<svg role="img" aria-labelledby=' "$diagram" ||
     ! rg -q '<title id=' "$diagram" ||
     ! rg -q '<desc id=' "$diagram"; then
    printf 'Diagram accessibility metadata is missing: %s\n' "$diagram" >&2
    exit 1
  fi

  if ! rg -q 'var\(--' "$diagram"; then
    printf 'Diagram does not use the site theme: %s\n' "$diagram" >&2
    exit 1
  fi

  if rg -q '<\?xml|<!DOCTYPE|foreignObject|style="[^"]*(fill|stroke): rgb' "$diagram"; then
    printf 'Diagram contains markup that is unsafe for inline themed use: %s\n' "$diagram" >&2
    exit 1
  fi
done

printf 'Site checks passed.\n'
