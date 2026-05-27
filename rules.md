# OpenSCAD Artwork Workflow Rules

These rules are the reusable checklist for this repo. Apply them to every PNG/SVG/DXF-to-OpenSCAD model unless the user explicitly asks for a different workflow.

## Source Conversion

- Convert PNG input through `sips`, `mkbitmap`, and `potrace`; do not assume `mkbitmap` can read PNG directly on macOS.
- Use `sips -s format bmp input.png --out input.bmp` before `mkbitmap`.
- Use `mkbitmap input.bmp -o input.pbm`.
- Use `potrace input.pbm -s --tight -o output.svg`.
- Export or convert the traced SVG to DXF only after the trace is visually acceptable.
- Keep source/intermediate files named clearly enough to reconstruct the path from raster to final model.

## DXF Geometry

- Treat old DXF entities `POLYLINE`, `VERTEX`, and `SEQEND` as unsupported for final OpenSCAD import.
- If OpenSCAD warns about unsupported DXF entities, do not use direct `import(file = "*.dxf")` in the final wrapper.
- Convert closed DXF contours into native OpenSCAD `polygon()` modules.
- Expand DXF bulge arcs into line segments during conversion.
- Preserve holes by detecting nested contours when the final model should keep holes open.
- For filled/color-separated art, it is acceptable to ignore inner holes only when the intended visual result is filled solid pieces.
- Measure source bounds from actual closed contour geometry and document those bounds in the final wrapper.

## File Separation

- Generated geometry files are not the editing surface.
- Final wrapper files are the editing surface.
- Use names like `<name>-dxf-geometry.scad` for generated raw polygon geometry.
- Use names like `<name>-dxf-filled-pieces.scad` for generated color/material-separated polygon pieces.
- Use names like `<name>-dxf-final.scad` for a final monochrome wrapper.
- Use names like `<name>-dxf-filled-color-final.scad` for a final colored wrapper.
- Generated files may include direct preview geometry at top level.
- Final wrappers must load generated files with `use <...>` instead of `include <...>`.

## Customizer Bar

- Treat the OpenSCAD Customizer bar as the default user interface.
- Put Customizer parameters near the top of every final wrapper.
- Use section headings in this order when applicable: `/* [Export] */`, `/* [Size] */`, `/* [Heights] */`, `/* [Shape] */`, `/* [Preview Colors] */`.
- Add ranges, steps, or dropdown options to every parameter that users should tune.
- Preserve current defaults unless the user explicitly asks for a geometry change.
- Do not hide visible geometry-defining numbers as unexplained inline literals.
- Keep derived values as expressions when they avoid duplicated controls.

Required final-wrapper controls for relief plaques:

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

For models without color-separated pieces, omit `export_part` only if there is truly nothing useful to export separately.

## Hex Coloring

- Use hex color strings for every preview color in final wrappers.
- Prefer variables such as `base_color`, `artwork_color`, and `piece_1_color` over inline colors.
- Do not use named OpenSCAD colors like `"white"`, `"black"`, `"red"`, or `"blue"` in final wrappers.
- Put all color variables under `/* [Preview Colors] */`.
- Use `color(base_color)`, `color(piece_1_color)`, and similar calls around visible pieces.
- Explain in comments that STL exports do not preserve color.
- For color prints, export separate STLs by `export_part` and assign materials/colors in OrcaSlicer or the print service UI.

Recommended color block:

```scad
/* [Preview Colors] */
base_color = "#f8f5ef";    // Backing plate preview color
artwork_color = "#111111"; // Single-color artwork preview color
piece_1_color = "#e63946"; // Piece 1 preview color
piece_2_color = "#f77f00"; // Piece 2 preview color
piece_3_color = "#fcbf49"; // Piece 3 preview color
piece_4_color = "#2a9d8f"; // Piece 4 preview color
piece_5_color = "#457b9d"; // Piece 5 preview color
piece_6_color = "#6a4c93"; // Piece 6 preview color
piece_7_color = "#111111"; // Piece 7 preview color
```

## Final Wrapper Structure

- Call `main();` once.
- Keep source bounds and derived scale values close together.
- Use `epsilon = 0.01;` for slight relief/base overlap.
- Put the broad base on `z = 0`.
- Center the final model in XY unless another assembly reference is more useful.
- Use `linear_extrude(height = relief_height + epsilon, convexity = 10)` for raised artwork.
- Apply `offset(delta = artwork_offset / scale_factor)` in source units when source geometry is scaled to millimeters.
- Keep base, artwork, offset, and piece modules separate and readable.

## Export Rules

- Export STL only after OpenSCAD validation/render succeeds.
- STL does not preserve OpenSCAD preview colors.
- Export `all` only for single-material preview or monochrome printing.
- Export `base`, `artwork`, and each `piece_N` separately for multi-material or color-separated printing.
- Save OrcaSlicer `.3mf` projects when color assignments, orientation, supports, or print settings matter.
- Do not hand-edit STL files; change the `.scad` source and re-export.

## Validation Rules

- Run the local OpenSCAD validation tool on final wrappers.
- Generate multi-angle previews and inspect them visually.
- Confirm imported STL dimensions are correct in millimeters.
- Slice in OrcaSlicer and inspect layer preview before printing or ordering.
- Check small islands, minimum wall paths, thin strokes, missing holes, unsupported islands, and accidental extra bodies.
- If details are too thin, increase `artwork_offset`, increase `target_width`, simplify the trace, or split pieces differently.
