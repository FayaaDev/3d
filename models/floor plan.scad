// Rough 3D-printable apartment floor-plan model traced from ../house.png
// Units: millimeters. This is a schematic display model, not an architectural drawing.

/* [Base] */

model_origin_x = 0;              // [-50:1:50]
model_origin_y = 0;              // [-50:1:50]
model_origin_z = 0;              // [0:0.1:10]
base_width = 140;                // [100:1:220]
base_depth = 185;                // [120:1:260]
base_thickness = 2.0;            // [1:0.1:5]
curve_segments = 48;             // [12:4:96]
epsilon = 0.01;                  // [0.001:0.001:0.1]

/* [Heights and widths] */

wall_thickness = 2.4;            // [1.2:0.1:5]
wall_height = 5.0;               // [2:0.1:12]
detail_height = 0.8;             // [0.2:0.1:3]
label_height = 0.7;              // [0.2:0.1:2]
label_size = 5.5;                // [3:0.1:10]
small_label_size = 4.4;          // [2:0.1:8]
door_swing_line_width = 0.7;     // [0.3:0.1:1.5]
door_swing_step_degrees = 5;     // [1:1:10]
window_line_width = 0.8;         // [0.3:0.1:1.5]

/* [Walls] */

floor_left_x = 18;                         // [0:0.5:50]
service_stack_right_x = 58;                // [35:0.5:80]
center_partition_x = 76;                   // [55:0.5:100]
right_exterior_x = 124;                    // [90:0.5:140]
balcony_bottom_y = 8;                      // [0:0.5:35]
bedroom_outer_wall_y = 34;                 // [20:0.5:70]
left_exterior_wall_bottom_y = 35;          // [20:0.5:70]
living_separator_lower_top_y = 82;         // [55:0.5:110]
living_separator_upper_bottom_y = 95;      // [75:0.5:120]
living_separator_upper_top_y = 108;        // [85:0.5:135]
closet_bedroom_divider_y = 90;             // [70:0.5:115]
bathroom_closet_divider_y = 104;           // [85:0.5:125]
storage_bathroom_divider_y = 135;          // [115:0.5:155]
storage_doorway_stub_bottom_y = 143;       // [120:0.5:165]
top_entry_jamb_bottom_y = 155;             // [135:0.5:175]
top_wall_stub_bottom_y = 156;              // [135:0.5:175]
floor_top_y = 168;                         // [140:0.5:185]
bedroom_window_wall_left_end_x = 40;       // [25:0.5:55]
bedroom_window_wall_right_start_x = 62;    // [45:0.5:75]
balcony_slider_wall_left_x = 82;           // [70:0.5:100]
balcony_slider_wall_split_x = 116;         // [95:0.5:125]
closet_bedroom_left_segment_end_x = 27;    // [18:0.5:40]
closet_bedroom_right_segment_start_x = 46; // [35:0.5:58]
bathroom_hall_jamb_x = 66;                 // [58:0.5:80]
bathroom_hall_jamb_bottom_y = 92;          // [80:0.5:105]
bathroom_hall_jamb_top_y = 105;            // [95:0.5:120]
top_entry_left_jamb_x = 68;                // [55:0.5:80]
kitchen_counter_left_x = 92;               // [80:0.5:110]
kitchen_counter_bottom_y = 124;            // [110:0.5:140]
kitchen_counter_top_y = 135;               // [120:0.5:155]

/* [Doors] */

entry_door_hinge_x = 66;                   // [55:0.5:85]
entry_door_hinge_y = 156;                  // [145:0.5:170]
entry_door_swing_radius = 12;              // [6:0.5:24]
entry_door_start_angle = 0;                // [-180:5:180]
entry_door_end_angle = 90;                 // [-180:5:180]

bathroom_door_hinge_x = 58;                // [45:0.5:75]
bathroom_door_hinge_y = 104;               // [90:0.5:120]
bathroom_door_swing_radius = 15;           // [8:0.5:24]
bathroom_door_start_angle = -45;           // [-180:5:180]
bathroom_door_end_angle = 35;              // [-180:5:180]

bedroom_door_hinge_x = 66;                 // [50:0.5:85]
bedroom_door_hinge_y = 90;                 // [75:0.5:110]
bedroom_door_swing_radius = 14;            // [8:0.5:24]
bedroom_door_start_angle = -90;            // [-180:5:180]
bedroom_door_end_angle = 0;                // [-180:5:180]


/* [Kitchen fixtures] */

kitchen_upper_cabinet_y = 158;             // [145:0.5:170]
kitchen_upper_cabinet_depth = 8;           // [4:0.5:16]
kitchen_upper_left_cabinet_x = 82;         // [70:0.5:100]
kitchen_upper_left_cabinet_width = 14;     // [6:0.5:24]
kitchen_upper_mid_cabinet_x = 96;          // [80:0.5:115]
kitchen_upper_mid_cabinet_width = 22;      // [10:0.5:35]
kitchen_upper_right_cabinet_x = 118;       // [105:0.5:125]
kitchen_upper_right_cabinet_width = 6;     // [3:0.5:14]
kitchen_sink_x = 100;                      // [85:0.5:115]
kitchen_sink_y = 159;                      // [145:0.5:172]
kitchen_sink_width = 13;                   // [6:0.5:24]
kitchen_sink_depth = 6;                    // [3:0.5:14]
kitchen_sink_corner_radius = 2;            // [0.5:0.5:5]
cooktop_x = 119;                           // [105:0.5:125]
cooktop_y = 158.8;                         // [145:0.1:172]
cooktop_burner_spacing = 4.8;              // [2:0.1:8]
cooktop_burner_radius = 1.6;               // [0.8:0.1:3]
kitchen_lower_cabinet_y = 126;             // [115:0.5:140]
kitchen_lower_cabinet_width = 12;          // [6:0.5:22]
kitchen_lower_cabinet_depth = 9;           // [4:0.5:16]
kitchen_lower_left_cabinet_x = 94;         // [80:0.5:110]
kitchen_lower_right_cabinet_x = 107;       // [95:0.5:122]
kitchen_island_x = 75;                     // [60:0.5:90]
kitchen_island_y = 126;                    // [115:0.5:140]
kitchen_island_width = 11;                 // [5:0.5:22]
kitchen_island_depth = 11;                 // [5:0.5:22]

/* [Bathroom and closet fixtures] */

tub_x = 25;                       // [18:0.5:40]
tub_y = 126;                      // [112:0.5:140]
tub_width = 22;                   // [10:0.5:35]
tub_depth = 8;                    // [4:0.5:16]
tub_corner_radius = 4;            // [1:0.5:8]
bathroom_sink_x = 23;             // [18:0.5:40]
bathroom_sink_y = 113;            // [104:0.5:126]
bathroom_sink_width = 5;          // [3:0.5:12]
bathroom_sink_depth = 7;          // [3:0.5:14]
toilet_x = 29;                    // [20:0.5:45]
toilet_y = 110;                   // [100:0.5:125]
toilet_radius = 3.0;              // [1.5:0.1:6]
closet_shelf_x = 21;              // [18:0.5:40]
closet_shelf_y = 94;              // [86:0.5:105]
closet_shelf_width = 26;          // [10:0.5:40]
closet_shelf_depth = 1.2;         // [0.6:0.1:3]

/* [Windows and sliders] */

bedroom_window_marker_start_x = 41;        // [25:0.5:55]
bedroom_window_marker_end_x = 61;          // [45:0.5:75]
bedroom_window_marker_y = 34;              // [20:0.5:70]
living_slider_marker_start_x = 83;         // [70:0.5:100]
living_slider_marker_end_x = 113;          // [95:0.5:124]
living_slider_marker_y = 34;               // [20:0.5:70]

/* [Labels] */

storage_label_x = 38;             // [20:0.5:58]
storage_label_y = 152;            // [140:0.5:165]
kitchen_label_x = 107;            // [85:0.5:125]
kitchen_label_y = 146;            // [130:0.5:160]
bathroom_label_x = 46;            // [25:0.5:60]
bathroom_label_y = 112;           // [100:0.5:130]
closet_label_x = 38;              // [20:0.5:58]
closet_label_y = 96;              // [86:0.5:108]
bedroom_label_x = 45;             // [25:0.5:70]
bedroom_label_y = 61;             // [40:0.5:85]
living_label_x = 103;             // [85:0.5:124]
living_label_y = 77;              // [55:0.5:100]
living_room_label_y = 70;         // [50:0.5:95]
balcony_label_x = 103;            // [85:0.5:124]
balcony_label_y = 18;             // [10:0.5:30]
counter_label_x = 82;             // [70:0.5:100]
counter_label_y = 158;            // [145:0.5:170]

/* [Preview Colors] */

base_color = "#f8f5ef";           // Base preview color
wall_color = "#111111";           // Wall preview color
fixture_color = "#777777";        // Fixture and door mark preview color
label_color = "#111111";          // Label preview color

$fn = curve_segments;

main();

module main() {
  color(base_color) base_plate();
  color(wall_color) walls();
  color(fixture_color) fixtures_and_door_marks();
  color(label_color) labels();
}

module base_plate() {
  translate([model_origin_x, model_origin_y, model_origin_z])
    cube([base_width, base_depth, base_thickness]);
}

module walls() {
  // Exterior outline, simplified from the PNG.
  wall_v(floor_left_x, left_exterior_wall_bottom_y, floor_top_y);        // Left exterior
  wall_h(floor_left_x, service_stack_right_x, floor_top_y);              // Storage top
  wall_v(service_stack_right_x, top_wall_stub_bottom_y, floor_top_y);     // Storage top-right stub
  wall_v(center_partition_x, top_wall_stub_bottom_y, floor_top_y);        // Kitchen top-left stub
  wall_h(center_partition_x, right_exterior_x, floor_top_y);              // Kitchen top
  wall_v(right_exterior_x, balcony_bottom_y, floor_top_y);                // Right exterior
  wall_h(center_partition_x, right_exterior_x, balcony_bottom_y);         // Balcony bottom
  wall_v(center_partition_x, balcony_bottom_y, living_separator_lower_top_y);
  wall_v(center_partition_x, living_separator_upper_bottom_y, living_separator_upper_top_y);

  // Bedroom lower exterior with a wide window/opening in the middle.
  wall_h(floor_left_x, bedroom_window_wall_left_end_x, bedroom_outer_wall_y);
  wall_h(bedroom_window_wall_right_start_x, center_partition_x, bedroom_outer_wall_y);

  // Balcony/living sliding door line and balcony side walls.
  wall_v(center_partition_x, balcony_bottom_y, bedroom_outer_wall_y);
  wall_h(balcony_slider_wall_left_x, balcony_slider_wall_split_x, bedroom_outer_wall_y);
  wall_h(balcony_slider_wall_split_x, right_exterior_x, bedroom_outer_wall_y);

  // Left service stack: storage, bathroom, closet.
  wall_h(floor_left_x, service_stack_right_x, storage_bathroom_divider_y);
  wall_h(floor_left_x, service_stack_right_x, bathroom_closet_divider_y);
  wall_h(floor_left_x, closet_bedroom_left_segment_end_x, closet_bedroom_divider_y);
  wall_h(closet_bedroom_right_segment_start_x, service_stack_right_x, closet_bedroom_divider_y);
  wall_v(service_stack_right_x, closet_bedroom_divider_y, storage_bathroom_divider_y);
  wall_v(service_stack_right_x, storage_doorway_stub_bottom_y, top_wall_stub_bottom_y);

  // Bathroom door opening and short hall walls.
  wall_v(bathroom_hall_jamb_x, bathroom_hall_jamb_bottom_y, bathroom_hall_jamb_top_y);
  wall_h(service_stack_right_x, bathroom_hall_jamb_x, bathroom_closet_divider_y);

  // Top entry/kitchen doorway jambs.
  wall_v(top_entry_left_jamb_x, top_entry_jamb_bottom_y, floor_top_y);
  wall_v(center_partition_x, top_entry_jamb_bottom_y, floor_top_y);

  // Kitchen counter boundary accents.
  wall_h(kitchen_counter_left_x, right_exterior_x, kitchen_counter_top_y);
  wall_v(kitchen_counter_left_x, kitchen_counter_bottom_y, kitchen_counter_top_y);
  wall_h(kitchen_counter_left_x, right_exterior_x, kitchen_counter_bottom_y);
}

module fixtures_and_door_marks() {
  // Kitchen fixtures: counter, sink, cooktop, and lower cabinets.
  fixture(kitchen_upper_left_cabinet_x, kitchen_upper_cabinet_y, kitchen_upper_left_cabinet_width, kitchen_upper_cabinet_depth);
  fixture(kitchen_upper_mid_cabinet_x, kitchen_upper_cabinet_y, kitchen_upper_mid_cabinet_width, kitchen_upper_cabinet_depth);
  fixture(kitchen_upper_right_cabinet_x, kitchen_upper_cabinet_y, kitchen_upper_right_cabinet_width, kitchen_upper_cabinet_depth);
  rounded_fixture(kitchen_sink_x, kitchen_sink_y, kitchen_sink_width, kitchen_sink_depth, kitchen_sink_corner_radius);
  cooktop(cooktop_x, cooktop_y);
  fixture(kitchen_lower_left_cabinet_x, kitchen_lower_cabinet_y, kitchen_lower_cabinet_width, kitchen_lower_cabinet_depth);
  fixture(kitchen_lower_right_cabinet_x, kitchen_lower_cabinet_y, kitchen_lower_cabinet_width, kitchen_lower_cabinet_depth);
  fixture(kitchen_island_x, kitchen_island_y, kitchen_island_width, kitchen_island_depth);

  // Bathroom fixtures.
  rounded_fixture(tub_x, tub_y, tub_width, tub_depth, tub_corner_radius);
  fixture(bathroom_sink_x, bathroom_sink_y, bathroom_sink_width, bathroom_sink_depth);
  translate([model_origin_x + toilet_x, model_origin_y + toilet_y, model_origin_z + base_thickness])
    cylinder(h = detail_height, r = toilet_radius);

  // Closet shelving hint.
  fixture(closet_shelf_x, closet_shelf_y, closet_shelf_width, closet_shelf_depth);

  // Door swing marks as shallow raised curves/lines.
  door_swing(entry_door_hinge_x, entry_door_hinge_y, entry_door_swing_radius, entry_door_start_angle, entry_door_end_angle);
  door_swing(bathroom_door_hinge_x, bathroom_door_hinge_y, bathroom_door_swing_radius, bathroom_door_start_angle, bathroom_door_end_angle);
  door_swing(bedroom_door_hinge_x, bedroom_door_hinge_y, bedroom_door_swing_radius, bedroom_door_start_angle, bedroom_door_end_angle);

  // Window/slider hints.
  thin_line(bedroom_window_marker_start_x, bedroom_window_marker_y, bedroom_window_marker_end_x, bedroom_window_marker_y, window_line_width);
  thin_line(living_slider_marker_start_x, living_slider_marker_y, living_slider_marker_end_x, living_slider_marker_y, window_line_width);
}

module labels() {
  label("storage", storage_label_x, storage_label_y, label_size);
  label("kitchen", kitchen_label_x, kitchen_label_y, label_size);
  label("bathroom", bathroom_label_x, bathroom_label_y, small_label_size);
  label("closet", closet_label_x, closet_label_y, small_label_size);
  label("bedroom", bedroom_label_x, bedroom_label_y, label_size);
  label("living / dining", living_label_x, living_label_y, small_label_size);
  label("room", living_label_x, living_room_label_y, small_label_size);
  label("balcony", balcony_label_x, balcony_label_y, label_size);
  label("C", counter_label_x, counter_label_y, small_label_size);
}

module wall_h(x1, x2, y) {
  translate([model_origin_x + min(x1, x2), model_origin_y + y - wall_thickness / 2, model_origin_z + base_thickness])
    cube([abs(x2 - x1), wall_thickness, wall_height]);
}

module wall_v(x, y1, y2) {
  translate([model_origin_x + x - wall_thickness / 2, model_origin_y + min(y1, y2), model_origin_z + base_thickness])
    cube([wall_thickness, abs(y2 - y1), wall_height]);
}

module fixture(x, y, w, d) {
  translate([model_origin_x + x, model_origin_y + y, model_origin_z + base_thickness])
    cube([w, d, detail_height]);
}

module rounded_fixture(x, y, w, d, r) {
  translate([model_origin_x + x, model_origin_y + y, model_origin_z + base_thickness])
    linear_extrude(height = detail_height)
      rounded_rect_2d(w, d, r);
}

module cooktop(x, y) {
  for (dx = [0, cooktop_burner_spacing])
    for (dy = [0, cooktop_burner_spacing])
      translate([model_origin_x + x + dx, model_origin_y + y + dy, model_origin_z + base_thickness])
        cylinder(h = detail_height, r = cooktop_burner_radius);
}

module label(text_value, x, y, size_value) {
  translate([model_origin_x + x, model_origin_y + y, model_origin_z + base_thickness + epsilon])
    linear_extrude(height = label_height)
      text(text_value, size = size_value, halign = "center", valign = "center");
}

module thin_line(x1, y1, x2, y2, width) {
  hull() {
    translate([model_origin_x + x1, model_origin_y + y1, model_origin_z + base_thickness]) cylinder(h = detail_height, r = width / 2);
    translate([model_origin_x + x2, model_origin_y + y2, model_origin_z + base_thickness]) cylinder(h = detail_height, r = width / 2);
  }
}

module door_swing(cx, cy, radius, start_angle, end_angle) {
  for (angle = [start_angle : door_swing_step_degrees : end_angle - door_swing_step_degrees]) {
    x1 = cx + radius * cos(angle);
    y1 = cy + radius * sin(angle);
    x2 = cx + radius * cos(angle + door_swing_step_degrees);
    y2 = cy + radius * sin(angle + door_swing_step_degrees);
    thin_line(x1, y1, x2, y2, door_swing_line_width);
  }
}

module rounded_rect_2d(w, d, r) {
  hull() {
    translate([r, r]) circle(r = r);
    translate([w - r, r]) circle(r = r);
    translate([r, d - r]) circle(r = r);
    translate([w - r, d - r]) circle(r = r);
  }
}
