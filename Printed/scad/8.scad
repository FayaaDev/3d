/* [Export] */
export_part = "all";          // [all, base, artwork]

/* [Size] */
target_width = 120;            // [40:1:220] Final artwork width in mm
base_margin = 20;              // [0:0.5:30] Border around the artwork

/* [Heights] */
base_thickness = 2.0;          // [1:0.2:6] Flat backing plate thickness
relief_height = 2.4;           // [0.6:0.2:8] Raised artwork height above the base

/* [Shape] */
base_corner_radius = 3;        // [0:0.5:12] Rounded backing plate corners
artwork_offset = 0.20;         // [-0.5:0.05:1.5] Grow/shrink artwork contours in mm
show_base = true;              // Add a backing plate

/* [Preview Colors] */
base_color = "#f1ede3";       // STL exports do not preserve preview colors
artwork_color = "#111111";    // STL exports do not preserve preview colors

epsilon = 0.01;

source_artwork_file = "../exports/tham-cleaned-monochrome-traced-openscad-plain.svg";
source_artwork_width_px = 816.666667;
source_artwork_height_px = 301.333333;
svg_unit_to_mm = 25.4 / 96;
source_artwork_center_x_adjustment = -19.9661392942;
source_artwork_center_y_adjustment = -7.4175333716;

source_artwork_width_mm = source_artwork_width_px * svg_unit_to_mm;
source_artwork_height_mm = source_artwork_height_px * svg_unit_to_mm;

artwork_scale = target_width / source_artwork_width_mm;
target_height = source_artwork_height_mm * artwork_scale;
base_fit_clearance = max(0, artwork_offset) + 0.5;
base_width = target_width + (show_base ? 2 * (base_margin + base_fit_clearance) : 0);
base_height = target_height + (show_base ? 2 * (base_margin + base_fit_clearance) : 0);

main();

module main() {
    if (export_part == "base") {
        linear_extrude(height = base_thickness)
            backing_plate_2d();
    } else if (export_part == "artwork") {
        artwork_3d();
    } else {
        if (show_base) {
            color(base_color)
                linear_extrude(height = base_thickness)
                    backing_plate_2d();
        }

        color(artwork_color)
            artwork_3d();
    }
}

module artwork_3d() {
    translate([0, 0, show_base ? base_thickness - epsilon : 0])
        linear_extrude(height = relief_height + (show_base ? epsilon : 0))
            artwork_profile_2d();
}

module artwork_profile_2d() {
    offset(delta = artwork_offset)
        imported_artwork_2d();
}

module imported_artwork_2d() {
    translate([source_artwork_center_x_adjustment, source_artwork_center_y_adjustment])
        scale([artwork_scale, artwork_scale])
            translate([-source_artwork_width_mm / 2, -source_artwork_height_mm / 2])
            import(source_artwork_file, center = false);
}

module backing_plate_2d() {
    rounded_rectangle_2d(base_width, base_height, base_corner_radius);
}

module rounded_rectangle_2d(width, height, radius) {
    if (radius <= 0) {
        square([width, height], center = true);
    } else {
        offset(r = radius)
            square([width - 2 * radius, height - 2 * radius], center = true);
    }
}
