// Model: apartment-floorplan-plaque.scad
// Source: ../apartment.png
// Units: millimeters
//
// Parametric, FDM-friendly architectural floor-plan plaque derived from the
// provided apartment plan image. This is a clean, schematic reconstruction of
// the visible walls/openings rather than a literal trace of every furniture line.
// STL exports do not preserve preview colors; export parts separately if needed.

/* [Export] */
export_part = "all";          // [all, base, walls, labels]

/* [Size] */
target_width = 140;           // [80:1:240] Final floor-plan width in mm
base_margin = 8;              // [2:0.5:20] Border around the plan

/* [Heights] */
base_thickness = 2.4;         // [1:0.2:8] Flat plaque thickness
wall_height = 6.0;            // [2:0.2:16] Raised wall height above the base
wall_thickness = 4.8;         // [1.2:0.1:10] Wall thickness in mm
label_height = 0.7;           // [0.2:0.1:2] Embossed room-label height
base_chamfer_height = 1.0;    // [0:0.1:3] Top-edge chamfer height on plaque
wall_top_bevel_height = 0.8;  // [0:0.1:3] Small bevel on wall tops

/* [Shape] */
base_corner_radius = 6;       // [0:0.5:20] Rounded plaque corner radius
base_edge_chamfer = 1.2;      // [0:0.1:4] Horizontal inset of plaque top face
wall_top_setback = 0.35;      // [0:0.05:1.5] Horizontal inset for wall-top bevel
artwork_offset = 0.15;        // [-0.5:0.05:1.5] Grow/shrink wall footprints in mm
show_base = true;             // Add a backing plaque

/* [Labels] */
main_label_size = 6.0;        // [3:0.1:12] Main room label size in mm
secondary_label_size = 4.5;   // [2:0.1:10] Smaller hall label size in mm

/* [Preview Colors] */
base_color = "#f2efe8";      // Plaque preview color
wall_color = "#111111";      // Wall preview color
label_color = "#1f2937";     // Label preview color

// Approximate source bounds reconstructed from the PNG floor plan.
source_min_x = 0;
source_min_y = 0;
source_width = 168;
source_depth = 160;

epsilon = 0.01;
$fn = 56;

scale_factor = target_width / source_width;
target_depth = source_depth * scale_factor;
base_width = target_width + 2 * base_margin;
base_depth = target_depth + 2 * base_margin;

main();

module main() {
  if (export_part == "all") {
    if (show_base)
      color(base_color) base_plate();

    color(wall_color) raised_walls();
    color(label_color) raised_labels();
  } else if (export_part == "base") {
    color(base_color) base_plate();
  } else if (export_part == "walls") {
    color(wall_color) raised_walls();
  } else if (export_part == "labels") {
    color(label_color) raised_labels();
  }
}

module base_plate() {
  chamfered_rounded_plate(base_width, base_depth, base_thickness, base_corner_radius, base_chamfer_height, base_edge_chamfer);
}

module raised_walls() {
  plan_transform(show_base ? base_thickness - epsilon : 0)
    beveled_plan_extrude(wall_height + (show_base ? epsilon : 0), wall_top_bevel_height, wall_top_setback / scale_factor)
      offset_plan(artwork_offset / scale_factor)
        architectural_wall_layout_2d();
}

module raised_labels() {
  plan_transform(show_base ? base_thickness - epsilon : 0)
    linear_extrude(height = label_height + (show_base ? epsilon : 0), convexity = 10)
      labels_2d();
}

module plan_transform(z_offset = 0) {
  translate([-target_width / 2, -target_depth / 2, z_offset])
    scale([scale_factor, scale_factor, 1])
      translate([-source_min_x, -source_min_y, 0])
        children();
}

module offset_plan(delta_value) {
  if (delta_value == 0)
    children();
  else
    offset(delta = delta_value)
      children();
}

module beveled_plan_extrude(total_height, bevel_height, top_inset) {
  straight_height = max(total_height - bevel_height, 0);

  if (straight_height > 0)
    linear_extrude(height = straight_height, convexity = 10)
      children();

  if (bevel_height > 0) {
    translate([0, 0, straight_height])
      linear_extrude(height = bevel_height, convexity = 10)
        offset_plan(-top_inset)
          children();
  }
}

module chamfered_rounded_plate(w, d, h, corner_r, chamfer_h, edge_inset) {
  safe_corner_r = min(corner_r, min(w, d) / 2);
  safe_chamfer_h = min(chamfer_h, h);
  top_w = max(w - 2 * edge_inset, 1);
  top_d = max(d - 2 * edge_inset, 1);
  body_h = max(h - safe_chamfer_h, 0);

  if (body_h > 0)
    linear_extrude(height = body_h, convexity = 10)
      rounded_rect_center_2d(w, d, safe_corner_r);

  if (safe_chamfer_h > 0)
    translate([0, 0, body_h])
      linear_extrude(
        height = safe_chamfer_h,
        scale = [top_w / w, top_d / d],
        convexity = 10
      )
        rounded_rect_center_2d(w, d, safe_corner_r);
}

module architectural_wall_layout_2d() {
  union() {
    // Exterior walls and window cutouts reconstructed from the PNG.
    rear_exterior_wall_segment(0, 33, 0);
    rear_exterior_wall_segment(51, 84, 0);
    rear_exterior_wall_segment(104, 160, 0);

    left_exterior_wall_segment(0, 0, 160);

    front_exterior_wall_segment(0, 24, 160);
    front_exterior_wall_segment(66, 99, 160);
    front_exterior_wall_segment(123, 160, 160);

    right_exterior_wall_segment(160, 0, 62);
    right_exterior_wall_segment(160, 86, 160);

    entry_bumpout_lower_wall_segment(160, 168, 62);
    entry_bumpout_right_wall_segment(168, 62, 68);
    entry_bumpout_right_wall_segment(168, 80, 86);
    entry_bumpout_upper_wall_segment(160, 168, 86);

    // Bedroom enclosure with door gap to living room.
    bedroom_upper_wall_segment(0, 52, 62);
    bedroom_upper_wall_segment(68, 84, 62);
    bedroom_right_wall_segment(84, 0, 62);

    // Central hall and bathroom separation.
    central_hall_right_wall_segment(104, 0, 46);
    central_hall_right_wall_segment(104, 64, 86);
    bathroom_upper_wall_segment(104, 160, 62);

    // Small right-side hall with door gap from living/kitchen.
    entry_hall_left_wall_segment(128, 62, 86);
    entry_hall_lower_wall_segment(128, 138, 62);
    entry_hall_lower_wall_segment(152, 168, 62);
  }
}

module labels_2d() {
  label_2d("LIVING ROOM", 52, 103, main_label_size / scale_factor);
  label_2d("KITCHEN", 126, 110, main_label_size / scale_factor);
  label_2d("BEDROOM", 42, 26, main_label_size / scale_factor);
  label_2d_rot("HALL", 92, 29, 90, 3.4 / scale_factor);
  label_2d("BATHROOM", 136, 31, 4.8 / scale_factor);
  label_2d("HALL", 148, 77, 3.8 / scale_factor);
}

module label_2d(text_value, x, y, size_value) {
  translate([x, y])
    text(text_value, size = size_value, halign = "center", valign = "center", spacing = 1.0);
}

module label_2d_rot(text_value, x, y, angle, size_value) {
  translate([x, y])
    rotate(angle)
      text(text_value, size = size_value, halign = "center", valign = "center", spacing = 1.0);
}

module horizontal_wall_segment(start_x, end_x, center_y) {
  wall_t = wall_thickness / scale_factor;

  translate([min(start_x, end_x), center_y - wall_t / 2])
    square([abs(end_x - start_x), wall_t]);
}

module vertical_wall_segment(center_x, start_y, end_y) {
  wall_t = wall_thickness / scale_factor;

  translate([center_x - wall_t / 2, min(start_y, end_y)])
    square([wall_t, abs(end_y - start_y)]);
}

module rear_exterior_wall_segment(start_x, end_x, center_y) {
  horizontal_wall_segment(start_x, end_x, center_y);
}

module front_exterior_wall_segment(start_x, end_x, center_y) {
  horizontal_wall_segment(start_x, end_x, center_y);
}

module left_exterior_wall_segment(center_x, start_y, end_y) {
  vertical_wall_segment(center_x, start_y, end_y);
}

module right_exterior_wall_segment(center_x, start_y, end_y) {
  vertical_wall_segment(center_x, start_y, end_y);
}

module entry_bumpout_lower_wall_segment(start_x, end_x, center_y) {
  horizontal_wall_segment(start_x, end_x, center_y);
}

module entry_bumpout_upper_wall_segment(start_x, end_x, center_y) {
  horizontal_wall_segment(start_x, end_x, center_y);
}

module entry_bumpout_right_wall_segment(center_x, start_y, end_y) {
  vertical_wall_segment(center_x, start_y, end_y);
}

module bedroom_upper_wall_segment(start_x, end_x, center_y) {
  horizontal_wall_segment(start_x, end_x, center_y);
}

module bedroom_right_wall_segment(center_x, start_y, end_y) {
  vertical_wall_segment(center_x, start_y, end_y);
}

module central_hall_right_wall_segment(center_x, start_y, end_y) {
  vertical_wall_segment(center_x, start_y, end_y);
}

module bathroom_upper_wall_segment(start_x, end_x, center_y) {
  horizontal_wall_segment(start_x, end_x, center_y);
}

module entry_hall_left_wall_segment(center_x, start_y, end_y) {
  vertical_wall_segment(center_x, start_y, end_y);
}

module entry_hall_lower_wall_segment(start_x, end_x, center_y) {
  horizontal_wall_segment(start_x, end_x, center_y);
}

module rounded_rect_center_2d(w, d, r) {
  safe_r = min(r, min(w, d) / 2);

  if (safe_r <= 0) {
    square([w, d], center = true);
  } else {
    hull() {
      translate([-w / 2 + safe_r, -d / 2 + safe_r]) circle(r = safe_r);
      translate([ w / 2 - safe_r, -d / 2 + safe_r]) circle(r = safe_r);
      translate([-w / 2 + safe_r,  d / 2 - safe_r]) circle(r = safe_r);
      translate([ w / 2 - safe_r,  d / 2 - safe_r]) circle(r = safe_r);
    }
  }
}
