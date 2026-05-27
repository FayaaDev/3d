---
name: openscad
description: "Create and repair OpenSCAD models, especially PNG/SVG/DXF artwork reliefs. Use this skill whenever the user mentions OpenSCAD, PNG tracing, Potrace, DXF conversion, unsupported DXF entities, polygon geometry repair, Customizer bars, hex-colored models, preview images, or STL export for 3D printing."
---

# OpenSCAD Artwork Relief Skill

Create, repair, validate, preview, and export OpenSCAD models. In this repo, the primary workflow is converting PNG artwork into DXF, repairing unsupported DXF geometry into native OpenSCAD polygons, and producing final `.scad` wrappers with Customizer bar controls and hex preview colors.

## First Read

When working in this repo, read these durable docs instead of relying on legacy scratch files:

- `AGENTS.md` for the overall project workflow.
- `rules.md` for Customizer, hex color, file separation, and export rules.
- `dxf.md` when debugging old DXF imports and unsupported entity warnings.

`potrace.md` may be deleted. The Potrace commands are repeated in `AGENTS.md` and summarized below.

## Tooling

OpenSCAD must be installed. The helper scripts in `tools/` locate either the CLI binary or the macOS app bundle.

```bash
brew install openscad
```

Available tools:

```bash
./tools/validate.sh model.scad
./tools/preview.sh model.scad output.png [--camera=x,y,z,tx,ty,tz,dist] [--size=800x600]
./tools/multi-preview.sh model.scad output_dir/
./tools/export-stl.sh model.scad output.stl [-D 'param=value']
./tools/extract-params.sh model.scad
./tools/render-with-params.sh model.scad output.png -D 'param=value'
```

Run these from `.agents/skills/openscad/` or call them by full relative path from the repo root.

## Canonical PNG To Final SCAD Workflow

Use this sequence for image artwork unless the user provides a cleaner vector source.

1. Prepare a high-contrast PNG with solid artwork and minimal noise.
2. Convert PNG to BMP, then PBM, then SVG:

```bash
sips -s format bmp input.png --out input.bmp
mkbitmap input.bmp -o input.pbm
potrace input.pbm -s --tight -o output.svg
```

3. Export or convert the traced SVG to DXF after the trace looks acceptable.
4. Inspect the DXF. Expect old `POLYLINE`, `VERTEX`, and `SEQEND` records to be unsupported by OpenSCAD direct import.
5. If OpenSCAD warns about unsupported DXF entities, convert closed DXF contours into native OpenSCAD `polygon()` modules.
6. Put generated polygon modules in `models/<name>-dxf-geometry.scad` or `models/<name>-dxf-filled-pieces.scad`.
7. Put all editable behavior in `models/<name>-dxf-final.scad` or `models/<name>-dxf-filled-color-final.scad`.
8. Validate, preview, export STL, and inspect the sliced result in OrcaSlicer.

Do not let a final wrapper rely on `import(file = "*.dxf")` when OpenSCAD reports unsupported DXF entities. It may validate while exporting only a backing plate or partial geometry.

## DXF Repair Pattern

When OpenSCAD shows warnings like:

```text
WARNING: Unsupported DXF Entity 'SEQEND'
WARNING: Unsupported DXF Entity 'VERTEX'
WARNING: Unsupported DXF Entity 'POLYLINE'
```

repair the DXF by converting it to native OpenSCAD geometry:

- Parse closed polyline contours.
- Expand bulge arcs into line segments.
- Measure source bounds from the closed contours.
- Preserve nested contours as holes when the artwork requires holes.
- Generate one module for the full artwork, or one module per filled/color piece.
- Add a small top-level `linear_extrude()` preview in generated files if helpful.
- Load generated geometry from final wrappers with `use <...>`, not `include <...>`.

Final wrappers should scale source units into millimeters using measured bounds:

```scad
source_min_x = 0;
source_min_y = 0;
source_width = 1200;
source_depth = 515;

scale_factor = target_width / source_width;
target_depth = source_depth * scale_factor;
```

## Required Customizer And Color Pattern

Every final wrapper should expose user controls through the OpenSCAD Customizer bar. Use these sections when applicable:

```scad
/* [Export] */
export_part = "all";       // [all, base, artwork, piece_1, piece_2]

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

/* [Preview Colors] */
base_color = "#f8f5ef";    // Backing plate preview color
piece_1_color = "#e63946"; // Piece 1 preview color
piece_2_color = "#111111"; // Piece 2 preview color
```

Rules:

- Use hex strings for all preview colors.
- Do not use named colors in final wrappers.
- Keep colors in variables, not inline literals.
- Explain in comments that STL does not preserve color.
- Use `export_part` to export separate STLs for slicer/material assignment.

## Final Wrapper Template

Use this as the default shape for generated final wrappers and adapt names/pieces as needed.

```scad
// Model: artwork_dxf_filled_color_final.scad
// Source: ../output.dxf
// Units: millimeters
// STL exports do not preserve preview colors; export separate parts for color printing.

use <artwork-dxf-filled-pieces.scad>

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
show_base = true;          // Add a backing plate when export_part is all

/* [Preview Colors] */
base_color = "#f8f5ef";    // Backing plate preview color
piece_1_color = "#111111"; // Artwork preview color

source_min_x = 0;
source_min_y = 0;
source_width = 1200;
source_depth = 515;

epsilon = 0.01;
$fn = 48;

scale_factor = target_width / source_width;
target_depth = source_depth * scale_factor;
base_width = target_width + 2 * base_margin;
base_depth = target_depth + 2 * base_margin;

main();

module main() {
  if (export_part == "all") {
    if (show_base)
      color(base_color) base_plate();
    colored_artwork();
  } else if (export_part == "base") {
    color(base_color) base_plate();
  } else if (export_part == "artwork") {
    colored_artwork();
  } else if (export_part == "piece_1") {
    color(piece_1_color) raised_piece_1();
  }
}

module colored_artwork() {
  color(piece_1_color) raised_piece_1();
}

module raised_piece_1() {
  raised_artwork_piece()
    artwork_piece_1_2d();
}

module raised_artwork_piece() {
  translate([-target_width / 2, -target_depth / 2, show_base ? base_thickness - epsilon : 0])
    scale([scale_factor, scale_factor, 1])
      translate([-source_min_x, -source_min_y, 0])
        linear_extrude(height = relief_height + (show_base ? epsilon : 0), convexity = 10)
          offset_artwork_2d()
            children();
}

module offset_artwork_2d() {
  if (artwork_offset == 0)
    children();
  else
    offset(delta = artwork_offset / scale_factor)
      children();
}

module base_plate() {
  rounded_plate(base_width, base_depth, base_thickness, base_corner_radius);
}

module rounded_plate(w, d, h, r) {
  safe_r = min(r, min(w, d) / 2);

  if (safe_r <= 0) {
    translate([-w / 2, -d / 2, 0])
      cube([w, d, h]);
  } else {
    hull() {
      translate([-w / 2 + safe_r, -d / 2 + safe_r, 0]) cylinder(h = h, r = safe_r);
      translate([ w / 2 - safe_r, -d / 2 + safe_r, 0]) cylinder(h = h, r = safe_r);
      translate([-w / 2 + safe_r,  d / 2 - safe_r, 0]) cylinder(h = h, r = safe_r);
      translate([ w / 2 - safe_r,  d / 2 - safe_r, 0]) cylinder(h = h, r = safe_r);
    }
  }
}
```

## Validation Workflow

After creating or editing a final wrapper:

1. Validate syntax:

```bash
./.agents/skills/openscad/tools/validate.sh models/model.scad
```

2. Generate multi-angle previews:

```bash
./.agents/skills/openscad/tools/multi-preview.sh models/model.scad exports/model_previews
```

3. View the generated PNG previews with the `read` tool and inspect top/isometric/side views.
4. Export STL only after the model looks right:

```bash
./.agents/skills/openscad/tools/export-stl.sh models/model.scad exports/model.stl
```

5. For color-separated output, export one part at a time:

```bash
./.agents/skills/openscad/tools/export-stl.sh models/model.scad exports/model_base.stl -D 'export_part="base"'
./.agents/skills/openscad/tools/export-stl.sh models/model.scad exports/model_piece_1.stl -D 'export_part="piece_1"'
```

6. Open the STL(s) in OrcaSlicer, confirm size in millimeters, slice, and inspect layer preview.

## Printability Guidance

- Default to PLA/FDM decorative relief unless specified otherwise.
- Use a broad flat base on `z = 0`.
- Prefer `base_thickness = 2.0` and `relief_height = 2.0` to `2.4` for plaques.
- Use `artwork_offset = 0.2` to `0.4` when traced details are too thin.
- Avoid final FDM details thinner than about `1.6 mm`; prefer `2.0 mm` for reliability.
- If tiny islands vanish in the slicer, increase `target_width`, increase `artwork_offset`, simplify the trace, or split into larger pieces.
- Treat OrcaSlicer layer preview as the practical printability checkpoint.

## Skill-Creator Notes

This skill was streamlined from a generic OpenSCAD helper into a repo-specific PNG/DXF artwork workflow. Good test prompts for future iteration:

- "Turn this PNG logo into a color-separated OpenSCAD relief with Customizer controls."
- "OpenSCAD warns about unsupported DXF POLYLINE/VERTEX entities; fix the workflow and make the final scad."
- "Refactor this final wrapper so all colors are hex variables and all dimensions appear in the Customizer bar."

For a formal skill improvement pass, create eval prompts from those cases and compare outputs against the old skill using the `skill-creator` eval viewer.
