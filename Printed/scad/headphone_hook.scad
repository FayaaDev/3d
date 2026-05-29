// Parametric wall-mounted headphone hook
// Units: millimeters
// Print orientation: place the flat wall side of the plate on the build plate.

$fn = 48;

// Main required dimensions
plate_height = 80;
plate_width = 50;
plate_thickness = 6;
hook_projection = 55;

// Hook shape
hook_width = 50;
hook_base_height = 22;
hook_tip_height = 14;
hook_corner_radius = 3;
front_lip_rise = 7;
front_lip_depth = 7;
front_lip_ramp_depth = 10;

// Root reinforcement on the plate face
root_pad_width = 33;
root_pad_height = 30;
root_pad_thickness = 6;
root_pad_radius = 6;

// Screw holes for 4 mm screws
screw_hole_diameter = 6;
screw_spacing = 52;
screw_head_diameter = 8.5;
screw_head_depth = 2.5;

// Edge detail
plate_corner_radius = 4;
clearance = 0.15;

module rounded_rect_2d(width, height, radius) {
  safe_radius = min(radius, min(width, height) / 2 - 0.01);
  offset(r = safe_radius)
    square([
      max(0.01, width - 2 * safe_radius),
      max(0.01, height - 2 * safe_radius)
    ], center = true);
}

module rounded_box(size, radius) {
  linear_extrude(height = size[2])
    rounded_rect_2d(size[0], size[1], radius);
}

module screw_holes() {
  for (y_pos = [-screw_spacing / 2, screw_spacing / 2]) {
    translate([0, y_pos, -clearance])
      cylinder(h = plate_thickness + 2 * clearance, d = screw_hole_diameter);

    if (screw_head_depth > 0 && screw_head_diameter > screw_hole_diameter) {
      translate([0, y_pos, plate_thickness - screw_head_depth])
        cylinder(
          h = screw_head_depth + clearance,
          d1 = screw_hole_diameter,
          d2 = screw_head_diameter
        );
    }
  }
}

module hook_body() {
  hook_end_z = plate_thickness + hook_projection;
  lip_ramp_start_z = hook_end_z - front_lip_depth - front_lip_ramp_depth;
  lip_start_z = hook_end_z - front_lip_depth;

  // Main arm tapers slightly as it projects from the wall plate.
  hull() {
    translate([0, 0, plate_thickness])
      rounded_box([hook_width, hook_base_height, 0.2], hook_corner_radius);
    translate([0, 0, lip_ramp_start_z])
      rounded_box([hook_width, hook_tip_height, 0.2], hook_corner_radius);
  }

  // The front lip grows gradually, keeping overhangs near 45 degrees or less.
  hull() {
    translate([0, 0, lip_ramp_start_z])
      rounded_box([hook_width, hook_tip_height, 0.2], hook_corner_radius);
    translate([0, front_lip_rise / 2, lip_start_z])
      rounded_box([hook_width, hook_tip_height + front_lip_rise, 0.2], hook_corner_radius);
  }

  translate([0, front_lip_rise / 2, lip_start_z])
    rounded_box([hook_width, hook_tip_height + front_lip_rise, front_lip_depth], hook_corner_radius);
}

module model() {
  difference() {
    union() {
      rounded_box([plate_width, plate_height, plate_thickness], plate_corner_radius);

      translate([0, 0, plate_thickness])
        rounded_box([root_pad_width, root_pad_height, root_pad_thickness], root_pad_radius);

      hook_body();
    }

    screw_holes();
  }
}

model();
