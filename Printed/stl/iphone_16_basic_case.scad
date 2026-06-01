// Basic iPhone 16 snap-on case approximation
// All dimensions are in millimeters.
// IMPORTANT: These values are approximate and should be verified against
// official Apple accessory drawings or measured hardware before printing.
// This model is intended as a simple starting point, not a production-ready case.

$fn = 32;

// --- Phone and case parameters ---
phone_length = 149.6;
phone_width = 71.5;
phone_thickness = 8.25;
clearance = 0.5;
wall_thickness = 2.2;
back_thickness = 1.8;
corner_radius = 8.0;

// Small rim left at the top and bottom of the open-ended shell.
// Increase this if the side rails feel too flexible.
end_lip = 4.0;

// --- Closed bottom parameters ---
// Continuous bottom band improves drop protection but blocks port access while installed.
closed_bottom = true;

// --- Camera cutout parameters ---
// Approximate rounded-rectangle placeholder near the rear top-left.
camera_cutout_width = 28.0;
camera_cutout_height = 24.0;
camera_cutout_radius = 3.0;
camera_cutout_x = -phone_width / 2 + 18.0;
camera_cutout_y = phone_length / 2 - 20.0;
camera_cutout_extra = 0.4;

// --- Button cutout parameters ---
// Positions are approximate distances from case center.
volume_slot_width = 2.8;
volume_slot_height = 26.0;
volume_slot_y = 22.0;

mute_slot_width = 2.8;
mute_slot_height = 10.0;
mute_slot_y = 47.0;

power_slot_width = 2.8;
power_slot_height = 28.0;
power_slot_y = 20.0;

// --- Inner back engraving parameters ---
// Recessed text is subtracted into the interior back wall.
// Keep inner_engraving_depth less than back_thickness so it cannot break through.
enable_inner_engraving = true;
inner_engraving_text = "FAYAA";
inner_engraving_depth = 0.6;
inner_engraving_size = 10.0;
inner_engraving_offset_x = 0.0;
inner_engraving_offset_y = 0.0;
inner_engraving_font = "Liberation Sans:style=Bold";

// --- Side engraving parameters ---
// Recessed text is subtracted from the right exterior side wall.
// If it is hidden by a button slot, adjust side_engraving_offset_y.
enable_side_engraving = true;
side_engraving_text = "FAYAA";
side_engraving_depth = 0.6;
side_engraving_size = 10.0;
side_engraving_offset_x = 0.0;
side_engraving_offset_y = 0.0;
side_engraving_font = "Liberation Sans:style=Bold";

button_slot_depth_extra = 2.0;
button_slot_z = back_thickness + phone_thickness / 2;

// --- Derived dimensions ---
inner_length = phone_length + 2 * clearance;
inner_width = phone_width + 2 * clearance;
inner_depth = phone_thickness + clearance;

outer_length = inner_length + 2 * wall_thickness;
outer_width = inner_width + 2 * wall_thickness;
outer_depth = back_thickness + inner_depth;

// --- Helpers ---
module rounded_rect_2d(size = [10, 10], radius = 2) {
    safe_radius = min(radius, min(size[0], size[1]) / 2 - 0.01);

    // Offset is quick for this simple 2D profile and avoids expensive 3D minkowski.
    offset(r = safe_radius)
        square([size[0] - 2 * safe_radius, size[1] - 2 * safe_radius], center = true);
}

module rounded_box(size = [10, 10, 2], radius = 2) {
    linear_extrude(height = size[2])
        rounded_rect_2d([size[0], size[1]], radius);
}

module case_outer_shell() {
    rounded_box([outer_width, outer_length, outer_depth], corner_radius);
}

module phone_cavity() {
    // Starts above the back plate, leaving a back_thickness rear panel.
    translate([0, 0, back_thickness])
        rounded_box([
            inner_width,
            inner_length,
            inner_depth + 0.2
        ], max(corner_radius - wall_thickness, 1));
}

module open_top_cutout() {
    // Remove only the top wall band while keeping the bottom lip for protection.
    slot_length = wall_thickness * 2 + end_lip + 0.2;

    translate([0, outer_length / 2 - slot_length / 2 + 0.1, back_thickness])
        cube([outer_width + 2, slot_length, outer_depth + 1], center = false);
}

module bottom_cutouts() {
    if (!closed_bottom) {
        // Optional full bottom opening for variants that need cable access.
        translate([-(outer_width + 2) / 2, -outer_length / 2 - 0.1, back_thickness])
            cube([outer_width + 2, wall_thickness + end_lip + 0.2, outer_depth + 1], center = false);
    }
}

module rear_camera_cutout() {
    translate([camera_cutout_x, camera_cutout_y, -0.1])
        linear_extrude(height = back_thickness + camera_cutout_extra)
            rounded_rect_2d(
                [camera_cutout_width, camera_cutout_height],
                camera_cutout_radius
            );
}

module left_side_slot(y_pos, slot_height) {
    translate([
        -outer_width / 2 - 0.1,
        y_pos - slot_height / 2,
        button_slot_z - volume_slot_width / 2
    ])
        cube([
            wall_thickness + button_slot_depth_extra,
            slot_height,
            volume_slot_width
        ], center = false);
}

module right_side_slot(y_pos, slot_height) {
    translate([
        outer_width / 2 - wall_thickness - button_slot_depth_extra + 0.1,
        y_pos - slot_height / 2,
        button_slot_z - power_slot_width / 2
    ])
        cube([
            wall_thickness + button_slot_depth_extra,
            slot_height,
            power_slot_width
        ], center = false);
}

module button_cutouts() {
    // Left edge: mute switch and volume buttons.
    left_side_slot(mute_slot_y, mute_slot_height);
    left_side_slot(volume_slot_y, volume_slot_height);

    // Right edge: power button.
    right_side_slot(power_slot_y, power_slot_height);
}

module inner_back_engraving_cutout() {
    if (enable_inner_engraving) {
        safe_inner_depth = min(inner_engraving_depth, back_thickness - 0.2);

        // On the inner back wall: reads correctly when looking into the case from above.
        translate([
            inner_engraving_offset_x,
            inner_engraving_offset_y,
            back_thickness - safe_inner_depth
        ])
            linear_extrude(height = safe_inner_depth + 0.01)
                text(
                    inner_engraving_text,
                    size = inner_engraving_size,
                    font = inner_engraving_font,
                    halign = "center",
                    valign = "center"
                );
    }
}

module side_engraving_cutout() {
    if (enable_side_engraving) {
        safe_side_depth = min(side_engraving_depth, wall_thickness - 0.2);

        // On the right exterior side wall: reads horizontally from outside the case.
        // side_engraving_offset_x moves along case length; side_engraving_offset_y moves up/down thickness.
        translate([
            outer_width / 2 - safe_side_depth + 0.01,
            side_engraving_offset_x,
            back_thickness + inner_depth / 2 + side_engraving_offset_y
        ])
            rotate([90, 0, 90])
                linear_extrude(height = safe_side_depth + 0.02)
                    text(
                        side_engraving_text,
                        size = side_engraving_size,
                        font = side_engraving_font,
                        halign = "center",
                        valign = "center"
                    );
    }
}

// --- Main model ---
// Coordinate convention:
// X = width, Y = length, Z = thickness. Back plate lies at Z = 0..back_thickness.

difference() {
    case_outer_shell();
    phone_cavity();
    open_top_cutout();
    bottom_cutouts();
    rear_camera_cutout();
    button_cutouts();
    inner_back_engraving_cutout();
    side_engraving_cutout();
}
