# OpenSCAD Artwork Workflow Rules

This is the canonical workflow source for this repo. Apply these rules to PNG/SVG/DXF-to-OpenSCAD work unless the user explicitly asks for a different workflow.

## Naming And Language

- Prefer descriptive names in code, comments, parameter names, module names, and explanations.
- Avoid compressed or vague names like `hseg`, `vseg`, `walls_2d`, `tmp`, `shape`, or `part` when a clearer name is practical.
- Name geometry by architectural or modeling role when possible, such as `front_exterior_wall_segment`, `door_opening_gap`, `bathroom_upper_wall_segment`, or `architectural_wall_layout_2d`.
- Improve naming clarity when refactoring unless preserving a stable external API or explicit user request matters more.
- Structure code so future edits can be made by reading names rather than decoding coordinates alone.

## Pathway Decision

Before converting any PNG, classify the source. If intent is unclear, ask:

> Is this PNG a technical drawing / floor plan / diagram that should be rebuilt cleanly, or artistic contours / logo artwork that should be traced?

Choose one pathway:

- **Technical drawing pathway:** Use the PNG as visual reference and rebuild directly in OpenSCAD with clean primitives, descriptive modules, consistent feature widths, intentional openings, and editable dimensions. Prefer this for floor plans, diagrams, mechanical layouts, architectural plaques, and dimensioned objects.
- **Artistic contour pathway:** Convert the PNG through Potrace, inspect SVG/DXF geometry, repair unsupported DXF entities, and preserve the source silhouette or artwork character. Prefer this for logos, calligraphy, silhouettes, badges, signs, and decorative reliefs.
- **Hybrid pathway:** Trace expressive contour artwork but manually rebuild technical features, text labels, bases, borders, holes, and other dimension-critical geometry.

## Technical Drawing Reconstruction

- Do not trace a floor plan, technical diagram, or dimensioned layout by default just because it arrived as a PNG.
- Use the PNG as reference and rebuild clean geometry directly in OpenSCAD when editability, consistent dimensions, or printability matters more than exact pixel fidelity.
- Represent architectural or technical features with named modules such as `front_exterior_wall_segment`, `door_opening_gap`, `bathroom_upper_wall_segment`, or `mounting_hole_cutout`.
- Normalize repeated dimensions into parameters such as wall thickness, base margin, label height, opening width, corner radius, and target width.
- Document intentional simplifications near the affected dimensions or modules, for example when furniture, shadows, raster noise, or tiny annotation lines are omitted.
- Validate the rebuilt model visually against the source, but prioritize printable, editable geometry over literal pixel tracing.

## Artistic Contour Conversion

- Prepare a high-contrast source with solid artwork and minimal noise before tracing.
- On macOS, do not assume `mkbitmap` can read PNG directly.
- Convert PNG input through BMP, PBM, then SVG:

```bash
sips -s format bmp input.png --out input.bmp
mkbitmap input.bmp -o input.pbm
potrace input.pbm -s --tight -o output.svg
```

- Keep the SVG as an inspection artifact.
- Export or convert the traced SVG to DXF only after the trace is visually acceptable.
- Simplify excessive node counts when possible to avoid heavy or fragile OpenSCAD geometry.
- Remove tiny artifacts that will not print reliably unless the user explicitly wants maximum fidelity.

## DXF Repair

Treat these OpenSCAD warnings as a hard signal to stop using direct DXF import in final wrappers:

```text
WARNING: Unsupported DXF Entity 'SEQEND'
WARNING: Unsupported DXF Entity 'VERTEX'
WARNING: Unsupported DXF Entity 'POLYLINE'
```

When they appear:

- Convert closed DXF contours into native OpenSCAD `polygon()` modules.
- Expand DXF bulge arcs into line segments.
- Measure source bounds from actual closed contour geometry and document those bounds in the final wrapper.
- Preserve nested contours as holes when the final model should keep holes open.
- For filled/color-separated art, ignore inner holes only when the intended visual result is filled solid pieces.
- Prefer native OpenSCAD polygon geometry over final-wrapper `import(file = "*.dxf")` for old or unsupported DXF files.

## File Roles

```text
input.png                         Source raster artwork
input.bmp / input.pbm             Temporary Potrace inputs
output.svg                        Potrace vector trace
output.dxf                        DXF exported from traced artwork
models/<name>-reference-final.scad
                                  Manually rebuilt technical drawing / diagram wrapper
models/<name>-dxf-geometry.scad   Generated raw polygon geometry
models/<name>-dxf-filled-pieces.scad
                                  Generated color/material-separated pieces
models/<name>-dxf-final.scad      Editable final monochrome wrapper
models/<name>-dxf-filled-color-final.scad
                                  Editable final color-separated wrapper
exports/<name>.stl                Generated export, never hand-edited
```

- Generated geometry files are not the editing surface.
- Final wrapper files are the editing surface.
- Generated files may include direct preview geometry at top level.
- Final wrappers must load generated geometry with `use <...>`, not `include <...>`.

## Final Wrapper Requirements

- Call `main();` once.
- Put Customizer parameters near the top.
- Use Customizer sections in this order when applicable: `/* [Export] */`, `/* [Size] */`, `/* [Heights] */`, `/* [Shape] */`, `/* [Preview Colors] */`.
- Add ranges, steps, or dropdown options to user-tunable parameters.
- Include `target_width`, `base_margin`, `base_thickness`, `relief_height`, `base_corner_radius`, `artwork_offset`, and `show_base` for relief plaques.
- Include `export_part` when separate base/artwork/piece exports are useful.
- Preserve current defaults unless the user explicitly asks for a geometry change.
- Keep source bounds and derived scale values close together.
- Use `epsilon = 0.01;` or another small overlap for relief/base booleans.
- Put the broad base on `z = 0`.
- Center the final model in XY unless another assembly reference is more useful.
- Keep base, raised artwork, offset artwork, and individual piece modules separate.
- Do not hide visible geometry-defining numbers as unexplained inline literals.

Required relief-plaque control pattern:

```scad
/* [Export] */
export_part = "all";       // [all, base, artwork, piece_1]

/* [Size] */
target_width = 120;        // [40:1:220] Final artwork width in mm
base_margin = 4;           // [0:0.5:15] Border around the artwork

/* [Heights] */
base_thickness = 2.0;      // [1:0.2:6] Flat backing plate thickness
relief_height = 2.4;       // [0.6:0.2:8] Raised artwork height above the base

/* [Shape] */
base_corner_radius = 3;    // [0:0.5:12] Rounded backing plate corners
artwork_offset = 0.25;     // [-0.5:0.05:1.5] Grow/shrink artwork contours in mm
show_base = true;          // Add a backing plate
```

## Hex Coloring

- Use hex color strings for every preview color in final wrappers.
- Do not use named OpenSCAD colors like `"white"`, `"black"`, `"red"`, or `"blue"` in final wrappers.
- Prefer variables such as `base_color`, `artwork_color`, and `piece_1_color` over inline colors.
- Put all color variables under `/* [Preview Colors] */`.
- Explain in comments that STL exports do not preserve preview color.
- For color prints, export separate STLs by `export_part` and assign materials/colors in OrcaSlicer or the print service UI.

Recommended color block:

```scad
/* [Preview Colors] */
base_color = "#f8f5ef";    // Backing plate preview color
artwork_color = "#111111"; // Single-color artwork preview color
piece_1_color = "#e63946"; // Piece 1 preview color
piece_2_color = "#f77f00"; // Piece 2 preview color
```

## Export And Validation

- Run the local OpenSCAD validation tool on final wrappers.
- Generate multi-angle previews and inspect them visually.
- Export STL only after validation and preview inspection pass.
- STL does not preserve OpenSCAD preview colors.
- Export `all` only for single-material preview or monochrome printing.
- Export `base`, `artwork`, and each `piece_N` separately for multi-material or color-separated printing.
- Confirm imported STL dimensions are correct in millimeters.
- Slice in OrcaSlicer and inspect layer preview before printing or ordering.
- Check small islands, minimum wall paths, thin strokes, missing holes, unsupported islands, and accidental extra bodies.
- If details are too thin, increase `artwork_offset`, increase `target_width`, simplify the trace, or split pieces differently.
- Do not hand-edit STL files; change the `.scad` source and re-export.

Standard commands:

```bash
./.agents/skills/openscad/tools/validate.sh models/model.scad
./.agents/skills/openscad/tools/multi-preview.sh models/model.scad exports/model_previews
./.agents/skills/openscad/tools/export-stl.sh models/model.scad exports/model.stl
./.agents/skills/openscad/tools/export-stl.sh models/model.scad exports/model_piece_1.stl -D 'export_part="piece_1"'
```

Before calling a model ready, confirm OpenSCAD validation passes, preview images look correct, STL dimensions are correct, and OrcaSlicer layer preview does not show missing walls, failed islands, accidental bodies, or unprintable details.
