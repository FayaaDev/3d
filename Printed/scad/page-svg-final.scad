// Parchment-edge relief plaque generated from a cleaned vector-only silhouette of page.png.
// The raster workflow used alpha-based PNG cleanup, potrace vectorization, and a final SVG cleanup pass.
// Units: millimeters.

$fn = 96;
epsilon = 0.01;

source_svg_path = "../svg/page_cleaned_for_openscad.svg";
source_artwork_width = 747;
source_artwork_height = 946;
source_artwork_aspect_ratio = source_artwork_width / source_artwork_height;

/* [Export] */
export_part = "all";          // [all, base, artwork]

/* [Size] */
target_width = 120;            // [40:1:220] Final artwork width in mm
base_margin = 4;               // [0:0.5:15] Border around the artwork

/* [Heights] */
base_thickness = 2.0;          // [1:0.2:6] Flat backing plate thickness
relief_height = 1.8;           // [0.6:0.2:8] Raised artwork height above the base

/* [Shape] */
base_corner_radius = 1.5;      // [0:0.5:12] Smoothing radius applied to the backing contour
artwork_offset = 0.2;          // [-0.5:0.05:1.5] Grow/shrink artwork contours in mm
show_base = true;              // Add a backing plate

/* [Preview Colors] */
base_color = "#5a4030";       // Backing plate preview color only; STL does not preserve color
artwork_color = "#e9c78f";    // Raised artwork preview color only; STL does not preserve color

target_height = target_width / source_artwork_aspect_ratio;
overall_width = target_width + 2 * base_margin;
overall_height = target_height + 2 * base_margin;

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

module contour_following_base_2d() {
  if (base_corner_radius <= 0) {
    offset(delta = base_margin)
      printable_artwork_2d();
  } else {
    offset(r = base_corner_radius)
      offset(delta = -base_corner_radius)
        offset(delta = base_margin)
          printable_artwork_2d();
  }
}

module base_plate_3d() {
  linear_extrude(height = base_thickness, convexity = 10)
    contour_following_base_2d();
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
