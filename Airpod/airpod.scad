include <BOSL2/std.scad>
include <BOSL2/hinges.scad>

/* [Visibility] */
show_box = true;
show_lid = true;
show_hinge_pin = true;
explode_view = true;

/* [Exploded View] */
explode_gap = 16;
lid_open_angle = 0;

/* [Dimensions (mm)] */
case_width = 60.8;
case_depth = 22.8;
case_height = 45.8;
body_height = 27.5;

/* [Fit] */
wall = 2.2;
bottom_wall = 2.2;
top_wall = 2.2;
clearance = 0.65;
corner_radius = 11;
split_gap = 0.8;

/* [Engraving] */
engrave_name = "Wathba";
engrave_depth = 0.8;
engrave_size = 7;

/* [Hinge] */
hinge_end_margin = 8;
hinge_segments = 9;
hinge_gap = 0.25;
hinge_pin_diameter = 1.75;
hinge_pin_extra = 4;

$fn = 40;

outer_width = case_width + wall * 2;
outer_depth = case_depth + wall * 2;
outer_height = case_height + bottom_wall + top_wall;
inner_width = case_width + clearance * 2;
inner_depth = case_depth + clearance * 2;
inner_height = case_height + clearance;
inner_corner_radius = max(corner_radius - wall, 0.1);
split_z = bottom_wall + body_height;
hinge_length = max(outer_width - hinge_end_margin * 2, 12);
hinge_offset = wall + split_gap;
hinge_knuckle_diameter = wall * 2 + split_gap;
hinge_clearance = split_gap / 2;
hinge_pin_length = hinge_length + hinge_pin_extra * 2;
body_offset_x = explode_view ? -(outer_width / 2 + explode_gap / 2) : 0;
lid_offset_x = explode_view ? (outer_width / 2 + explode_gap / 2) : 0;
hinge_axis = [0, outer_depth / 2, split_z];

if (show_box)
    translate([body_offset_x, 0, 0])
        box_cover();

if (show_lid)
    translate([lid_offset_x, 0, 0])
        xrot(-lid_open_angle, cp = hinge_axis)
            lid_cover();

if (show_hinge_pin && !explode_view)
    hinge_pin();

module rounded_box(size, radius) {
    safe_radius = min(radius, min(size[0], min(size[1], size[2])) / 2 - 0.01);

    hull()
        for (x = [safe_radius, size[0] - safe_radius])
            for (y = [safe_radius, size[1] - safe_radius])
                for (z = [safe_radius, size[2] - safe_radius])
                    translate([x, y, z])
                        sphere(r = safe_radius);
}

module shell_volume() {
    difference() {
        rounded_box([outer_width, outer_depth, outer_height], corner_radius);

        translate([
            (outer_width - inner_width) / 2,
            (outer_depth - inner_depth) / 2,
            bottom_wall
        ])
            rounded_box([inner_width, inner_depth, inner_height], inner_corner_radius);
    }
}

module body_mask() {
    cube([outer_width + 2, outer_depth + 2, split_z - split_gap / 2 + 1]);
}

module lid_mask() {
    translate([-1, -1, split_z + split_gap / 2])
        cube([
            outer_width + 2,
            outer_depth + 2,
            outer_height - split_z - split_gap / 2 + 2
        ]);
}

module box_cover() {
    union() {
        translate([-outer_width / 2, -outer_depth / 2, 0])
            difference() {
                intersection() {
                    shell_volume();
                    body_mask();
                }

                back_engraving();
            }

        body_hinge();
    }
}

module lid_cover() {
    union() {
        translate([-outer_width / 2, -outer_depth / 2, 0])
            intersection() {
                shell_volume();
                lid_mask();
            }

        lid_hinge();
    }
}

module back_engraving() {
    translate([
        outer_width / 2,
        outer_depth - engrave_depth + 0.02,
        bottom_wall + body_height * 0.45
    ])
        rotate([90, 0, 180])
            linear_extrude(height = engrave_depth + 0.05)
                text(
                    engrave_name,
                    size = engrave_size,
                    halign = "center",
                    valign = "center",
                    font = "Arial:style=Bold"
                );
}

module body_hinge() {
    translate(hinge_axis)
        xrot(-90)
            knuckle_hinge(
                length = hinge_length,
                segs = hinge_segments,
                offset = hinge_offset,
                arm_height = 0,
                arm_angle = 90,
                clear_top = true,
                gap = hinge_gap,
                clearance = hinge_clearance,
                knuckle_diam = hinge_knuckle_diameter,
                pin_diam = hinge_pin_diameter
            );
}

module lid_hinge() {
    translate(hinge_axis)
        xrot(-90)
            knuckle_hinge(
                length = hinge_length,
                segs = hinge_segments,
                offset = hinge_offset,
                inner = true,
                arm_height = 0,
                arm_angle = 90,
                clear_top = true,
                gap = hinge_gap,
                clearance = hinge_clearance,
                knuckle_diam = hinge_knuckle_diameter,
                pin_diam = hinge_pin_diameter
            );
}

module hinge_pin() {
    color("silver")
        translate(hinge_axis)
            xcyl(l = hinge_pin_length, d = hinge_pin_diameter, anchor = CENTER);
}
