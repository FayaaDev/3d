// Model: img_relief_from_dxf.scad
// Source: img.dxf
// Units: millimeters
//
// Creates a printable raised-relief plaque from the traced DXF artwork.

use <wath-geomtry.scad>

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

/* [Repair] */
final_trace_artwork_offset = 0.7; // [0:0.05:2] Extra fill for the small bottom-right trace

/* [Preview Colors] */
base_color = "#f8f5ef";    // Backing plate preview color
artwork_color = "#111111"; // Artwork preview color

// Bounding box measured from img.dxf closed polyline entities.
source_min_x = 301.210073;
source_min_y = 177.000000;
source_width = 597.660236;
source_depth = 275.984687;

// Source-space repair windows around the small final trace.
final_trace_lower_x = 675;
final_trace_lower_y = 177;
final_trace_lower_width = 90;
final_trace_lower_depth = 26;
final_trace_upper_x = 718;
final_trace_upper_y = 196;
final_trace_upper_width = 48;
final_trace_upper_depth = 19;

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
  union() {
    offset_dxf_artwork_2d(artwork_offset);
    final_trace_repair_2d();
  }
}

module offset_dxf_artwork_2d(offset_mm) {
  if (offset_mm == 0)
    img_dxf_artwork_2d();
  else
    offset(delta = offset_mm / scale_factor)
      img_dxf_artwork_2d();
}

module final_trace_repair_2d() {
  if (final_trace_artwork_offset > artwork_offset)
    intersection() {
      offset_dxf_artwork_2d(final_trace_artwork_offset);
      final_trace_repair_regions_2d();
    }
}

module final_trace_repair_regions_2d() {
  translate([final_trace_lower_x, final_trace_lower_y])
    square([final_trace_lower_width, final_trace_lower_depth]);

  translate([final_trace_upper_x, final_trace_upper_y])
    square([final_trace_upper_width, final_trace_upper_depth]);
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
