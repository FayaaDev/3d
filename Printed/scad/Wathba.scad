// Customizable separated-SVG raised-relief plaque template.
// STL exports do not preserve preview color; export base/artwork/pieces separately
// when assigning materials or colors in the slicer.

/* [Export] */
export_part = "all";        // [all, base, artwork, piece_1, piece_2, piece_3, piece_4, piece_5, piece_6]

/* [Size] */
target_width = 120;         // [40:1:260] Final artwork width in mm
base_margin = 4;            // [0:0.5:20] Border around the artwork

/* [Heights] */
base_thickness = 2.0;       // [0.8:0.2:8] Flat backing plate thickness
relief_height = 2.4;        // [0.4:0.2:10] Raised artwork height above the base

/* [Shape] */
base_corner_radius = 3;     // [0:0.5:20] Rounded backing plate corners
artwork_offset = 0.25;      // [-1:0.05:2] Grow/shrink artwork contours in mm
artwork_rotation = 0;       // [-180:1:180] Rotate artwork and base fit in degrees
mirror_artwork_x = false;   // Mirror artwork left/right
mirror_artwork_y = false;   // Mirror artwork front/back
show_base = true;           // Add a backing plate when export_part is all

/* [Preview Colors] */
base_color = "#d4d0c6";     // Backing plate preview color
piece_1_color = "#00131f";  // Left upper stroke, SVG id path5
piece_2_color = "#00131f";  // Left lower stroke, SVG id path4
piece_3_color = "#00131f";  // Center long stroke, SVG id path3
piece_4_color = "#00131f";  // Small middle detail, SVG id path2
piece_5_color = "#00131f";  // Right upper cap, SVG id path6
piece_6_color = "#00131f";  // Right main body and tail, SVG id path1

svg_file = "../svg/Wathba.svg";
svg_convexity = 10;
epsilon = 0.01;
$fn = 48;

// Bounds measured from docs/drawing.svg imported with center=false.
// The SVG uses millimeter units, so these source bounds are already in mm.
source_min_x = -182.0311238;
source_min_y = 22.7937325;
source_width = 606.9822213;
source_depth = 260.0960060;

scale_factor = target_width / source_width;
target_depth = source_depth * scale_factor;

rotated_artwork_width = abs(cos(artwork_rotation)) * target_width + abs(sin(artwork_rotation)) * target_depth;
rotated_artwork_depth = abs(sin(artwork_rotation)) * target_width + abs(cos(artwork_rotation)) * target_depth;
base_width = rotated_artwork_width + 2 * base_margin;
base_depth = rotated_artwork_depth + 2 * base_margin;

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
  }
}

module colored_artwork() {
  color(piece_1_color) raised_piece_1();
  color(piece_2_color) raised_piece_2();
  color(piece_3_color) raised_piece_3();
  color(piece_4_color) raised_piece_4();
  color(piece_5_color) raised_piece_5();
  color(piece_6_color) raised_piece_6();
}

module raised_piece_1() {
  raised_svg_piece("path5");
}

module raised_piece_2() {
  raised_svg_piece("path4");
}

module raised_piece_3() {
  raised_svg_piece("path3");
}

module raised_piece_4() {
  raised_svg_piece("path2");
}

module raised_piece_5() {
  raised_svg_piece("path6");
}

module raised_piece_6() {
  raised_svg_piece("path1");
}

module raised_svg_piece(svg_element_id) {
  translate([0, 0, show_base ? base_thickness - epsilon : 0])
    linear_extrude(height = relief_height + (show_base ? epsilon : 0), convexity = svg_convexity)
      transformed_svg_piece_2d(svg_element_id);
}

module transformed_svg_piece_2d(svg_element_id) {
  rotate(artwork_rotation)
    scale([mirror_artwork_x ? -1 : 1, mirror_artwork_y ? -1 : 1])
      translate([-target_width / 2, -target_depth / 2])
        scale([scale_factor, scale_factor])
          translate([-source_min_x, -source_min_y])
            offset_svg_piece_2d()
              import(file = svg_file, id = svg_element_id, center = false);
}

module offset_svg_piece_2d() {
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
