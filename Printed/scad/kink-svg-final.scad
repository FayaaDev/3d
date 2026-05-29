// Kink wearable crown made from the crown silhouette itself
// Source artwork: ../references/kink-tight.svg
// Units: millimeters

$fn = 128;
epsilon = 0.01;

artwork_svg_path = "../svg/kink-tight.svg";
artwork_aspect_ratio = 2627.837479 / 1739.739573;

/* [Export] */
export_part = "all";            // [all, left_half, right_half]

/* [Size] */
head_circumference = 600;        // [520:5:680] Wearer's head circumference in mm
fit_clearance = 6;               // [0:1:20] Extra inner circumference for wearable fit
motif_repeat_count = 5;          // [3:1:8] Number of crown motifs around the full ring

/* [Heights] */
crown_wall_thickness = 2.4;      // [1.6:0.2:6] Radial thickness of the wearable crown wall

/* [Shape] */
artwork_offset = 0.3;            // [-0.5:0.05:2] Grow or shrink the crown silhouette in mm
slice_count = 240;               // [120:10:420] More slices give a smoother wrapped crown

/* [Preview Colors] */
crown_color = "#ff9f1c";        // Preview color only; STL does not preserve color

inner_circumference = head_circumference + fit_clearance;
inner_radius = inner_circumference / (2 * PI);
outer_radius = inner_radius + crown_wall_thickness;
motif_wrap_width = inner_circumference / motif_repeat_count;
motif_height = motif_wrap_width / artwork_aspect_ratio;
wrapped_artwork_width = motif_wrap_width * motif_repeat_count;
slice_width = wrapped_artwork_width / slice_count;
crown_total_height = motif_height + 2 * artwork_offset;

function slice_center_x(index) = -wrapped_artwork_width / 2 + (index + 0.5) * slice_width;
function slice_rotation_degrees(index) = slice_center_x(index) / inner_radius * 180 / PI;

module repeated_crown_strip_2d() {
  union() {
    for (motif_index = [0 : motif_repeat_count - 1]) {
      translate([
        -wrapped_artwork_width / 2 + (motif_index + 0.5) * motif_wrap_width,
        motif_height / 2
      ])
        resize([motif_wrap_width, motif_height])
          import(file = artwork_svg_path, center = true);
    }
  }
}

module offset_crown_strip_2d() {
  offset(delta = artwork_offset)
    repeated_crown_strip_2d();
}

module wrapped_crown_slice_2d(slice_index) {
  translate([-slice_center_x(slice_index), 0])
    intersection() {
      offset_crown_strip_2d();
      translate([slice_center_x(slice_index), crown_total_height / 2])
        square([slice_width + epsilon, crown_total_height + 4 * abs(artwork_offset)], center = true);
    }
}

module wrapped_crown_wall_3d() {
  union() {
    for (slice_index = [0 : slice_count - 1]) {
      rotate([0, 0, slice_rotation_degrees(slice_index)])
        translate([0, outer_radius, 0])
          rotate([90, 0, 0])
            linear_extrude(height = crown_wall_thickness)
              wrapped_crown_slice_2d(slice_index);
    }
  }
}

module half_selector_3d(side) {
  selector_size = 2 * (outer_radius + motif_height + 40);

  if (side == "left") {
    translate([-selector_size, -selector_size, -epsilon])
      cube([selector_size, 2 * selector_size, crown_total_height + 40]);
  } else {
    translate([0, -selector_size, -epsilon])
      cube([selector_size, 2 * selector_size, crown_total_height + 40]);
  }
}

module selected_geometry() {
  if (export_part == "left_half") {
    intersection() {
      wrapped_crown_wall_3d();
      half_selector_3d("left");
    }
  } else if (export_part == "right_half") {
    intersection() {
      wrapped_crown_wall_3d();
      half_selector_3d("right");
    }
  } else {
    wrapped_crown_wall_3d();
  }
}

module preview_geometry() {
  color(crown_color)
    selected_geometry();
}

module main() {
  render(convexity = 10)
    preview_geometry();
}

main();
