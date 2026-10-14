# szahariev.com

Source for Stanislav Zahariev's personal writing and speaking site. It is a
custom multilingual Hugo site with no third-party theme, database, analytics,
or cookies. English is served from the root and Bulgarian from `/bg/`. A small
local script stores the visitor's light/dark theme choice in `localStorage`;
without JavaScript, the site follows the operating-system preference.

## Local development

Install Hugo Extended 0.168.0 or later, then run:

```sh
hugo server --buildDrafts
```

Open `http://localhost:1313`.

Build the production site with:

```sh
hugo --gc --minify --cleanDestinationDir
```

Run the local structural checks with:

```sh
./scripts/check.sh
```

## Diagrams

Article diagrams are authored in draw.io and published as inline SVG. Keep the
editable `.drawio` source beside its matching `.svg` export. See
[`assets/diagrams/README.md`](assets/diagrams/README.md) for the export and
theme-preparation workflow.

## Deployment

`.github/workflows/deploy.yml` publishes the generated site to GitHub Pages.
The workflow uses a pinned Hugo version, verifies its checksum, and pins each
GitHub-maintained action to a commit.
