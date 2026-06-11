# Deterministic Artwork Pipeline

This repo now has a deterministic local pipeline for the fixed `PNG -> SVG -> OpenSCAD -> STL -> CAD Viewer` artwork workflow.

## Scope

Supported now:

- single PNG input
- artwork / logo / calligraphy workflow
- single-color relief plaque output
- editable final `.scad`
- validation, previews, STL export, and CAD Viewer handoff

Not supported yet:

- arbitrary technical drawing reconstruction from images
- multi-color piece separation
- batch processing

## Prerequisites

Install these tools locally:

```bash
brew install imagemagick potrace openscad
```

Node.js is also required for the CLI and local web app.

## CLI Usage

Run the deterministic pipeline directly:

```bash
node scripts/artwork-relief-pipeline.mjs \
  --input web/uploads/2026-05-31T16-33-20-716Z-wathba.png \
  --output-dir exports/test-wathba-run \
  --name test-wathba
```

Optional parameters:

```bash
node scripts/artwork-relief-pipeline.mjs \
  --input web/uploads/2026-05-31T16-33-20-716Z-wathba.png \
  --output-dir exports/test-wathba-run \
  --name test-wathba \
  --target-width 120 \
  --base-margin 4 \
  --base-thickness 2 \
  --relief-height 2.4 \
  --base-corner-radius 3 \
  --artwork-offset 0.25 \
  --threshold 55
```

Show help:

```bash
node scripts/artwork-relief-pipeline.mjs --help
```

## Generated Artifacts

The pipeline writes intermediate and final artifacts under the chosen output directory:

```text
exports/<run>/
  <name>-refined.png
  <name>-potrace-input.pbm
  <name>-potrace.svg
  <name>-openscad-clean.svg
  <name>.stl
  manifest.json
  preview/
```

It also writes the editable final wrapper here:

```text
models/<name>-svg-final.scad
```

`manifest.json` records:

- artifact paths
- stage status
- stage timings
- tool versions
- CAD Viewer URL when available

## Local Web App

Start the local app:

```bash
node web/server.mjs
```

Then open:

```text
http://127.0.0.1:4317
```

Current app behavior:

- accepts one PNG upload
- runs the deterministic artwork pipeline locally
- streams stage progress
- returns a CAD Viewer link when the run completes

The `Technical Drawing` button remains intentionally unavailable in deterministic mode until that pathway has a constrained non-AI input model.

## Notes

- The generated `.scad` is the editing surface. Do not hand-edit exported STL files.
- STL files do not preserve OpenSCAD preview colors.
- If the threshold is wrong for a source image, rerun with a different `--threshold` value.
