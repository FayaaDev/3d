// Model: output_dxf_filled_color_relief.scad
// Source: ../output.dxf
// Units: millimeters
//
// Creates a filled, 7-color raised-relief plaque from the traced DXF artwork.
// Preview colors use hex strings. STL exports do not preserve color, so use
// export_part to create separate STLs and assign materials in the slicer.

use <filled-pieces.scad>

/* [Export] */
export_part = "all";       // [all, base, artwork, piece_1, piece_2, piece_3, piece_4, piece_5, piece_6, piece_7]

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
base_color = "#d4d0c6";    // Backing plate preview color
piece_1_color = "#ff5b05"; // Left upper stroke
piece_2_color = "#00131f"; // Left lower stroke
piece_3_color = "#00131f"; // Center long stroke
piece_4_color = "#00131f"; // Small middle detail cluster
piece_5_color = "#00131f"; // Upper middle mark
piece_6_color = "#00131f"; // Right main body and tail
piece_7_color = "#00131f"; // Right upper cap/mark

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
  } else if (export_part == "piece_2") {
    color(piece_2_color) raised_piece_2();
  } else if (export_part == "piece_3") {
    color(piece_3_color) raised_piece_3();
  } else if (export_part == "piece_4") {
    color(piece_4_color) raised_piece_4();
  } else if (export_part == "piece_5") {
    color(piece_5_color) raised_piece_5();
  } else if (export_part == "piece_6") {
    color(piece_6_color) raised_piece_6();
  } else if (export_part == "piece_7") {
    color(piece_7_color) raised_piece_7();
  }
}

module colored_artwork() {
  color(piece_1_color) raised_piece_1();
  color(piece_2_color) raised_piece_2();
  color(piece_3_color) raised_piece_3();
  color(piece_4_color) raised_piece_4();
  color(piece_5_color) raised_piece_5();
  color(piece_6_color) raised_piece_6();
  color(piece_7_color) raised_piece_7();
}

module raised_piece_1() {
  raised_artwork_piece()
    output_dxf_filled_piece_1_2d();
}

module raised_piece_2() {
  raised_artwork_piece()
    output_dxf_filled_piece_2_2d();
}

module raised_piece_3() {
  raised_artwork_piece()
    output_dxf_filled_piece_3_2d();
}

module raised_piece_4() {
  raised_artwork_piece()
    output_dxf_filled_piece_4_2d();
}

module raised_piece_5() {
  raised_artwork_piece()
    output_dxf_filled_piece_5_2d();
}

module raised_piece_6() {
  raised_artwork_piece()
    output_dxf_filled_piece_6_2d();
}

module raised_piece_7() {
  raised_artwork_piece()
    output_dxf_filled_piece_7_2d();
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
