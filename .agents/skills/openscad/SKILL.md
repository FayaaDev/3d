---
name: openscad
description: "Create and repair OpenSCAD models, especially PNG/SVG/DXF artwork reliefs and technical drawing reconstructions. Use when working with OpenSCAD, PNG tracing, Potrace, DXF conversion, unsupported DXF entities, polygon geometry repair, Customizer bars, hex-colored models, preview images, STL export, or OrcaSlicer print checks."
---

# OpenSCAD Skill

Use this skill to create, repair, validate, preview, and export OpenSCAD models in this repo.

## Canonical Rules

Follow repo `rules.md` for durable workflow requirements:

- PNG pathway selection.
- technical drawing reconstruction.
- artistic contour tracing.
- DXF repair policy.
- generated/final file separation.
- Customizer and hex-color requirements.
- STL export and OrcaSlicer validation rules.

Do not duplicate or override `rules.md` here. Update this skill only when tool usage, command syntax, or skill execution behavior changes.

## Tooling

OpenSCAD must be installed. The helper scripts in this skill locate either the CLI binary or the macOS app bundle.

```bash
brew install openscad
```

Run helper scripts from the repo root or from `.agents/skills/openscad/` with adjusted paths.

```bash
./.agents/skills/openscad/tools/validate.sh models/model.scad
./.agents/skills/openscad/tools/preview.sh models/model.scad exports/model.png
./.agents/skills/openscad/tools/multi-preview.sh models/model.scad exports/model_previews
./.agents/skills/openscad/tools/export-stl.sh models/model.scad exports/model.stl
./.agents/skills/openscad/tools/export-stl.sh models/model.scad exports/model_piece_1.stl -D 'export_part="piece_1"'
./.agents/skills/openscad/tools/extract-params.sh models/model.scad
./.agents/skills/openscad/tools/render-with-params.sh models/model.scad exports/model.png -D 'target_width=120'
```

## Execution Pattern

1. Inspect the input and classify PNGs as technical drawing, artistic contour artwork, or hybrid.
2. Read `rules.md` before building or reviewing a final wrapper.
3. Build editable OpenSCAD source, not hand-edited STL output.
4. Keep generated polygon geometry out of final wrapper logic.
5. Validate final wrappers with the local tools.
6. Generate multi-angle previews and inspect them visually.
7. Export STL only after validation and preview inspection pass.
8. For color/material-separated models, export separate STL files with `export_part`.
9. Treat OrcaSlicer layer preview as the practical printability checkpoint.

## PNG Conversion Shortcut

For artistic contour artwork on macOS, use this raster-to-vector path when tracing is appropriate:

```bash
sips -s format bmp input.png --out input.bmp
mkbitmap input.bmp -o input.pbm
potrace input.pbm -s --tight -o output.svg
```

Keep the SVG as an inspection artifact. Convert to DXF only after the trace looks acceptable.

## DXF Repair Signal

If OpenSCAD warns about these entities, stop using direct DXF import in final wrappers and convert closed contours into native `polygon()` modules:

```text
WARNING: Unsupported DXF Entity 'SEQEND'
WARNING: Unsupported DXF Entity 'VERTEX'
WARNING: Unsupported DXF Entity 'POLYLINE'
```

## Quality Gate

Before reporting a model ready, confirm:

- OpenSCAD validation passes.
- previews show the intended model from multiple angles.
- STL dimensions are correct in millimeters.
- OrcaSlicer layer preview shows no missing walls, failed islands, accidental bodies, or unprintable details.

## Skill Maintenance

Good prompts for checking this skill still triggers correctly:

- "Turn this PNG logo into a color-separated OpenSCAD relief with Customizer controls."
- "OpenSCAD warns about unsupported DXF POLYLINE/VERTEX entities; fix the workflow and make the final scad."
- "Refactor this final wrapper so all colors are hex variables and all dimensions appear in the Customizer bar."
