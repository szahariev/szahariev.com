# Diagrams

The `.drawio` files are the editable sources. The matching `.svg` files are
the web assets Hugo renders inline.

## Editing

1. Open the `.drawio` file in [app.diagrams.net](https://app.diagrams.net/) or
   the draw.io desktop application.
2. Keep labels as plain text. The sources deliberately use `html=0` so SVG
   exports do not depend on HTML `foreignObject` support.
3. Save the source, then regenerate all SVG exports from the site root:

```sh
./scripts/export-diagrams.sh
```

4. Run `./scripts/check.sh` and inspect the article in both site themes.

The export script invokes the CLI with a transparent background, no embedded
source or fonts, and the light export theme. The light setting is intentional:
it preserves the editor palette instead of allowing draw.io to remap it.

The preparation script maps the editor palette to the site's CSS properties,
so the inline SVG follows the site's own theme toggle rather than only the
operating-system color preference. It also restores the accessible title and
description that draw.io does not retain as part of the canvas.

## Palette

| Purpose              | Editor colour | Site property     |
|----------------------|---------------|-------------------|
| Node background      | `#141927`     | `--obsidian`      |
| Border and connector | `#2C3A52`     | `--steel`         |
| Boundary background  | `#172B47`     | `--body-glow`     |
| Emphasis border      | `#4F8FDC`     | `--accent`        |
| Primary connector    | `#71B0F5`     | `--accent-strong` |
| Secondary text       | `#8896A8`     | `--mist`          |
| Primary text         | `#EEF1F5`     | `--frost`         |
| Kicker text          | `#A8D2FF`     | `--accent-soft`   |

The dark colors make the source legible in the editor. The exported SVG uses
the CSS properties above and therefore works in both light and dark themes.
