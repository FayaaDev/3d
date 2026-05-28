// Apple logo relief plaque traced from appleclear.svg
// Units: millimeters

$fn = 64;

epsilon = 0.01;

/* [Export] */
export_part = "all";          // [all, base, artwork]

/* [Size] */
target_width = 120;            // [40:1:220] Final artwork width in mm
base_margin = 5;               // [0:0.5:15] Border around the artwork

/* [Heights] */
base_thickness = 2.0;          // [1:0.2:6] Flat backing plate thickness
relief_height = 2.4;           // [0.6:0.2:8] Raised artwork height above the base

/* [Shape] */
base_corner_radius = 5;        // [0:0.5:12] Rounded backing plate corners
artwork_offset = 0.2;          // [-0.5:0.05:1.5] Grow/shrink artwork contours in mm
show_base = true;              // Add a backing plate

/* [Preview Colors] */
base_color = "#f2f0ea";       // Backing plate preview color only; STL ignores color
artwork_color = "#111111";    // Raised artwork preview color only; STL ignores color

source_svg_path = "../references/appleclear-tight.svg";

source_artwork_width = 624.402;
source_artwork_height = 758.216;

artwork_scale = target_width / source_artwork_width;
target_height = source_artwork_height * artwork_scale;
base_width = target_width + 2 * base_margin;
base_height = target_height + 2 * base_margin;

module rounded_rectangle_2d(width, height, radius) {
  safe_radius = min(radius, min(width, height) / 2 - 0.01);

  if (safe_radius <= 0) {
    square([width, height], center = true);
  } else {
    offset(r = safe_radius)
      square([
        max(0.01, width - 2 * safe_radius),
        max(0.01, height - 2 * safe_radius)
      ], center = true);
  }
}

module centered_raw_artwork_2d() {
  scale([artwork_scale, artwork_scale])
    import(source_svg_path, center = true);
}

module offset_artwork_2d() {
  offset(delta = artwork_offset)
    centered_raw_artwork_2d();
}

module base_plate_3d() {
  linear_extrude(height = base_thickness)
    rounded_rectangle_2d(base_width, base_height, base_corner_radius);
}

module raised_artwork_3d() {
  translate([0, 0, show_base ? base_thickness - epsilon : 0])
    linear_extrude(height = relief_height + epsilon)
      offset_artwork_2d();
}

module assembled_model() {
  if (show_base) {
    union() {
      color(base_color)
        base_plate_3d();

      color(artwork_color)
        raised_artwork_3d();
    }
  } else {
    color(artwork_color)
      translate([0, 0, 0])
        linear_extrude(height = relief_height)
          offset_artwork_2d();
  }
}

module main() {
  if (export_part == "base") {
    base_plate_3d();
  } else if (export_part == "artwork") {
    if (show_base) {
      translate([0, 0, 0])
        linear_extrude(height = relief_height)
          offset_artwork_2d();
    } else {
      linear_extrude(height = relief_height)
        offset_artwork_2d();
    }
  } else {
    assembled_model();
  }
}

main();
