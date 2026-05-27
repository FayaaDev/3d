# AGENTS.md - PNG/DXF to OpenSCAD Relief Workflow

This repo turns image artwork into editable, printable OpenSCAD relief models. Act as a practical CAD assistant: preserve artwork intent, repair unsupported imported geometry, expose user controls in the OpenSCAD Customizer bar, and use hex preview colors in final models.

`potrace.md` is legacy scratch documentation and may be deleted. Durable workflow details live in `rules.md` and `.agents/skills/openscad/SKILL.md`.

## Read First

- Read `rules.md` before creating or reviewing final `.scad` wrappers.
- Use the local `openscad` skill for model creation, DXF repair, previews, validation, and STL export.
- Use `dxf.md` for background on old DXF `POLYLINE` / `VERTEX` / `SEQEND` failures.
- Do not put durable workflow updates in `potrace.md`.

## Canonical Workflow

1. Start from high-contrast PNG or clean vector artwork.
2. Convert PNG to BMP, then PBM, then SVG with Potrace tools.
3. Export or convert the traced SVG to DXF when the OpenSCAD workflow needs DXF geometry.
4. Inspect DXF structure, bounds, closed contours, holes, and entity types.
5. Expect old DXF entities to be unsupported by OpenSCAD direct import.
6. Convert unsupported DXF contours into native OpenSCAD `polygon()` modules.
7. Keep generated polygon geometry separate from editable final wrappers.
8. Build final wrappers with Customizer sections and hex color variables.
9. Export separate STLs for color/material-separated pieces when needed.
10. Validate in OpenSCAD, generate previews, export STL, and inspect layer preview in OrcaSlicer.

## Potrace Commands

Use this macOS PNG path because Homebrew `mkbitmap` and `potrace` usually do not read PNG directly:

```bash
sips -s format bmp input.png --out input.bmp
mkbitmap input.bmp -o input.pbm
potrace input.pbm -s --tight -o output.svg
```

Keep the SVG as an inspection artifact. Convert/export to DXF only after the trace looks acceptable.

## DXF Repair Rule

Treat these OpenSCAD warnings as a hard signal to stop using direct DXF import in the final model:

```text
WARNING: Unsupported DXF Entity 'SEQEND'
WARNING: Unsupported DXF Entity 'VERTEX'
WARNING: Unsupported DXF Entity 'POLYLINE'
```

When they appear, parse closed polyline contours, expand bulge arcs, calculate bounds from actual contours, preserve holes when needed, and generate native `polygon()` modules.

## File Roles

```text
input.png                         Source raster artwork
input.bmp / input.pbm             Temporary Potrace inputs
output.svg                        Potrace vector trace
output.dxf                        DXF exported from traced artwork
models/<name>-dxf-geometry.scad   Generated raw polygon geometry
models/<name>-dxf-filled-pieces.scad
                                  Generated color/material-separated pieces
models/<name>-dxf-final.scad      Editable final monochrome wrapper
models/<name>-dxf-filled-color-final.scad
                                  Editable final color-separated wrapper
exports/<name>.stl                Generated export, never hand-edited
```

Generated geometry may include a top-level preview extrusion. Final wrappers must load generated geometry with `use <...>`, not `include <...>`.

## Final Wrapper Requirements

- Call `main();` once.
- Group Customizer controls with `Export`, `Size`, `Heights`, `Shape`, and `Preview Colors` sections when applicable.
- Include controls for `target_width`, `base_margin`, `base_thickness`, `relief_height`, `base_corner_radius`, `artwork_offset`, and `show_base`.
- Include `export_part` for color-separated models.
- Use hex strings for preview colors; do not use named colors like `"white"` or `"black"` in final wrappers.
- Document measured source bounds near scaling values.
- Use `epsilon = 0.01;` or another small overlap for relief/base booleans.
- Keep base, raised artwork, offset artwork, and individual piece modules separate.

## Validation Commands

```bash
./.agents/skills/openscad/tools/validate.sh models/model.scad
./.agents/skills/openscad/tools/multi-preview.sh models/model.scad exports/model_previews
./.agents/skills/openscad/tools/export-stl.sh models/model.scad exports/model.stl
./.agents/skills/openscad/tools/export-stl.sh models/model.scad exports/model_piece_1.stl -D 'export_part="piece_1"'
```

Before calling a model ready, confirm OpenSCAD validation passes, preview images look correct, STL dimensions are correct, and OrcaSlicer layer preview does not show missing walls, tiny failed islands, accidental bodies, or unprintable details.

## Agent Behavior

- Prefer native OpenSCAD polygon geometry over direct DXF import for old or unsupported DXF files.
- Do not hand-edit generated STL files or massive generated polygon point lists unless there is no better repair path.
- Preserve user-provided dimensions and artwork intent unless they create unsafe or unprintable geometry.
- Keep durable process details in `rules.md` or the local skill, not in disposable scratch docs.
