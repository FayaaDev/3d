// World Cup trophy relief plaque traced from worldcup.png.
// Raster preprocessing used the alpha silhouette, then potrace generated the vector source.
// Photo-texture and reflective micro-details were intentionally removed for a durable printable plaque.
// Units: millimeters.

$fn = 96;
epsilon = 0.01;

source_svg_path = "../references/worldcup-work/worldcup-alpha-traced.svg";
source_artwork_width = 1398;
source_artwork_height = 3555;
source_artwork_aspect_ratio = source_artwork_width / source_artwork_height;

/* [Export] */
export_part = "all";          // [all, base, artwork]

/* [Size] */
target_width = 78;             // [40:1:220] Final artwork width in mm
base_margin = 6;               // [0:0.5:20] Border around the artwork

/* [Heights] */
base_thickness = 2.2;          // [1:0.2:6] Flat backing plate thickness
relief_height = 2.8;           // [0.6:0.2:8] Raised artwork height above the base

/* [Shape] */
base_corner_radius = 6;        // [0:0.5:16] Rounded backing plate corners
artwork_offset = 0.35;         // [-0.5:0.05:1.5] Grow/shrink artwork contours in mm
show_base = true;              // Add a backing plate

/* [Preview Colors] */
base_color = "#efe7da";       // Backing plate preview color only; STL does not preserve color
artwork_color = "#c9a227";    // Raised artwork preview color only; STL does not preserve color

target_height = target_width / source_artwork_aspect_ratio;
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
  resize([target_width, 0], auto = true)
    import(file = source_svg_path, center = true);
}

module printable_artwork_2d() {
  if (artwork_offset == 0) {
    centered_raw_artwork_2d();
  } else {
    offset(delta = artwork_offset)
      centered_raw_artwork_2d();
  }
}

module base_plate_3d() {
  linear_extrude(height = base_thickness)
    rounded_rectangle_2d(base_width, base_height, base_corner_radius);
}

module raised_artwork_3d() {
  translate([0, 0, show_base ? base_thickness - epsilon : 0])
    linear_extrude(height = relief_height + (show_base ? epsilon : 0), convexity = 10)
      printable_artwork_2d();
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
      linear_extrude(height = relief_height, convexity = 10)
        printable_artwork_2d();
  }
}

module main() {
  if (export_part == "base") {
    base_plate_3d();
  } else if (export_part == "artwork") {
    linear_extrude(height = relief_height, convexity = 10)
      printable_artwork_2d();
  } else {
    assembled_model();
  }
}

main();
