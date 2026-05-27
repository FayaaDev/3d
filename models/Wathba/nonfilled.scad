// Model: output_relief_from_dxf.scad
// Source: ../output.dxf
// Units: millimeters
//
// Creates a printable raised-relief plaque from the traced DXF artwork.

use <nonfilled_geometry.scad>

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
artwork_color = "#111111"; // Artwork preview color

// Bounding box measured from ../output.dxf closed polyline entities.
source_min_x = 0.000911;
source_min_y = 0.000000;
source_width = 1196.985363;
source_depth = 514.932532;

epsilon = 0.01;
$fn = 48;

scale_factor = target_width / source_width;
target_depth = source_depth * scale_factor;
base_width = target_width + 2 * base_margin;
base_depth = target_depth + 2 * base_margin;

main();

module main() {
  if (show_base)
    color(base_color) rounded_plate(base_width, base_depth, base_thickness, base_corner_radius);

  color(artwork_color) raised_dxf_artwork();
}

module raised_dxf_artwork() {
  translate([-target_width / 2, -target_depth / 2, show_base ? base_thickness - epsilon : 0])
    scale([scale_factor, scale_factor, 1])
      translate([-source_min_x, -source_min_y, 0])
        linear_extrude(height = relief_height + (show_base ? epsilon : 0), convexity = 10)
          dxf_artwork_2d();
}

module dxf_artwork_2d() {
  if (artwork_offset == 0)
    output_dxf_artwork_2d();
  else
    offset(delta = artwork_offset / scale_factor)
      output_dxf_artwork_2d();
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
