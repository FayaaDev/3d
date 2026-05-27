// Editable relief wrapper for logo.svg
// Units: millimeters

$fn = 48;
epsilon = 0.01;

/* [Export] */
export_part = "all";       // [all, base, artwork]

/* [Size] */
target_width = 120;         // [40:1:220] Final artwork width in mm
base_margin = 4;            // [0:0.5:15] Border around the artwork

/* [Heights] */
base_thickness = 2.0;       // [1:0.2:6] Flat backing plate thickness
relief_height = 2.4;        // [0.6:0.2:8] Raised artwork height above the base

/* [Shape] */
base_corner_radius = 3;     // [0:0.5:12] Softens the backing plate outline
artwork_offset = 0.25;      // [-0.5:0.05:1.5] Grow/shrink artwork contours in mm
show_base = true;           // Add a backing plate

/* [Preview Colors] */
base_color = "#f2efe8";    // STL export does not preserve preview colors
artwork_color = "#111111"; // STL export does not preserve preview colors

module source_logo_artwork_2d() {
  import("../logo.svg", center = true);
}

module scaled_logo_artwork_2d() {
  resize([target_width, 0], auto = true)
    source_logo_artwork_2d();
}

module raised_logo_artwork_2d() {
  if (artwork_offset == 0)
    scaled_logo_artwork_2d();
  else
    offset(delta = artwork_offset)
      scaled_logo_artwork_2d();
}

module backing_plate_2d() {
  if (base_corner_radius > 0)
    offset(r = base_corner_radius)
      offset(delta = base_margin)
        scaled_logo_artwork_2d();
  else
    offset(delta = base_margin)
      scaled_logo_artwork_2d();
}

module base_solid() {
  linear_extrude(height = base_thickness)
    backing_plate_2d();
}

module artwork_solid() {
  translate([0, 0, show_base ? base_thickness - epsilon : 0])
    linear_extrude(height = relief_height + epsilon)
      raised_logo_artwork_2d();
}

module main() {
  if (export_part == "base") {
    color(base_color)
      base_solid();
  } else if (export_part == "artwork") {
    color(artwork_color)
      artwork_solid();
  } else {
    if (show_base)
      color(base_color)
        base_solid();

    color(artwork_color)
      artwork_solid();
  }
}

main();
