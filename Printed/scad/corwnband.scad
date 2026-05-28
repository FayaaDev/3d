// Kink wearable crown
// Source artwork: ../references/kink-tight.svg
// Units: millimeters

$fn = 96;
epsilon = 0.01;

artwork_svg_path = "../svg/kink-tight.svg";
artwork_aspect_ratio = 2627.837479 / 1739.739573;

/* [Export] */
export_part = "all";            // [all, band, crest, left_half, right_half]

/* [Size] */
head_circumference = 600;        // [520:5:680] Wearer's head circumference in mm
fit_clearance = 6;               // [0:1:20] Extra inner circumference for wearable fit
target_width = 135;              // [80:1:220] Front crest width in mm

/* [Heights] */
band_height = 28;                // [15:1:60] Height of the circular band
band_wall_thickness = 2.4;       // [1.6:0.2:6] Radial thickness of the wearable band
crest_thickness = 2.4;           // [1.2:0.2:6] Front crest thickness

/* [Shape] */
artwork_offset = 0.3;            // [-0.5:0.05:2] Grow or shrink the crest artwork in mm
crest_bottom_overlap = 7;        // [0:0.5:20] Crest overlap into the band for strength
crest_vertical_offset = 0;       // [0:0.5:40] Additional crest lift above the default overlap position
show_band = true;                // Include the wearable band

/* [Preview Colors] */
band_color = "#f4efe4";         // Band preview color only; STL does not preserve color
crest_color = "#ff9f1c";        // Crest preview color only; STL does not preserve color

target_height = target_width / artwork_aspect_ratio;
inner_circumference = head_circumference + fit_clearance;
inner_radius = inner_circumference / (2 * PI);
outer_radius = inner_radius + band_wall_thickness;
crest_center_y = outer_radius + crest_thickness / 2 - epsilon;
crest_center_z = band_height - crest_bottom_overlap + crest_vertical_offset + target_height / 2;

module imported_artwork_2d() {
  resize([target_width, target_height])
    import(file = artwork_svg_path, center = true);
}

module offset_crest_2d() {
  offset(delta = artwork_offset)
    imported_artwork_2d();
}

module crown_band_3d() {
  difference() {
    cylinder(h = band_height, r = outer_radius);
    translate([0, 0, -epsilon])
      cylinder(h = band_height + 2 * epsilon, r = inner_radius);
  }
}

module front_crest_3d() {
  translate([0, crest_center_y, crest_center_z])
    rotate([90, 0, 0])
      linear_extrude(height = crest_thickness)
        offset_crest_2d();
}

module full_crown_geometry() {
  union() {
    if (show_band) {
      crown_band_3d();
    }

    front_crest_3d();
  }
}

module half_selector_3d(side) {
  selector_width = 2 * (outer_radius + target_width + 20);
  selector_depth = outer_radius + crest_thickness + 20;
  selector_height = band_height + crest_vertical_offset + target_height + 20;

  if (side == "left") {
    translate([-selector_width, -selector_depth / 2, -epsilon])
      cube([selector_width, selector_depth, selector_height]);
  } else {
    translate([0, -selector_depth / 2, -epsilon])
      cube([selector_width, selector_depth, selector_height]);
  }
}

module selected_geometry() {
  if (export_part == "band") {
    crown_band_3d();
  } else if (export_part == "crest") {
    front_crest_3d();
  } else if (export_part == "left_half") {
    intersection() {
      full_crown_geometry();
      half_selector_3d("left");
    }
  } else if (export_part == "right_half") {
    intersection() {
      full_crown_geometry();
      half_selector_3d("right");
    }
  } else {
    full_crown_geometry();
  }
}

module preview_geometry() {
  if (export_part == "band") {
    color(band_color)
      crown_band_3d();
  } else if (export_part == "crest") {
    color(crest_color)
      front_crest_3d();
  } else if (export_part == "left_half" || export_part == "right_half") {
    color(band_color)
      intersection() {
        crown_band_3d();
        half_selector_3d(export_part == "left_half" ? "left" : "right");
      }

    color(crest_color)
      intersection() {
        front_crest_3d();
        half_selector_3d(export_part == "left_half" ? "left" : "right");
      }
  } else {
    if (show_band) {
      color(band_color)
        crown_band_3d();
    }

    color(crest_color)
      front_crest_3d();
  }
}

module main() {
  render(convexity = 10)
    preview_geometry();
}

main();
