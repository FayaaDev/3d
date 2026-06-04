epsilon = 0.01;

/* [Export] */
export_part = "all";            // [all, base, artwork, main_artwork, accent]

/* [Size] */
target_width = 120;              // [40:1:220] Final artwork width in mm
base_margin = 4;                 // [0:0.5:15] Border around the artwork

/* [Heights] */
base_thickness = 2.0;            // [1:0.2:6] Flat backing plate thickness
relief_height = 2.4;             // [0.6:0.2:8] Raised artwork height above the base

/* [Shape] */
base_corner_radius = 3;          // [0:0.5:12] Rounded backing plate corners
artwork_offset = 0.20;           // [-0.5:0.05:1.5] Grow/shrink artwork contours in mm
show_base = true;                // Add a backing plate

/* [Preview Colors] */
base_color = "#f4efe7";         // STL export does not preserve preview color
main_artwork_color = "#10233d"; // STL export does not preserve preview color
accent_color = "#f36c21";       // STL export does not preserve preview color

source_artwork_width = 597.32947;
source_artwork_height = 256.75388;
artwork_scale_factor = target_width / source_artwork_width;
target_height = source_artwork_height * artwork_scale_factor;
base_plate_width = target_width + 2 * base_margin;
base_plate_height = target_height + 2 * base_margin;

main_artwork_svg_path = "../assets/og-image-main-openscad.svg";
accent_artwork_svg_path = "../assets/og-image-accent-openscad.svg";

main();

module main() {
    if (export_part == "all") {
        preview_assembly();
    } else if (export_part == "base") {
        base_plate_3d();
    } else if (export_part == "artwork") {
        combined_relief_3d();
    } else if (export_part == "main_artwork") {
        main_relief_3d();
    } else if (export_part == "accent") {
        accent_relief_3d();
    } else {
        preview_assembly();
    }
}

module preview_assembly() {
    if (show_base) {
        color(base_color)
            base_plate_3d();
    }

    color(main_artwork_color)
        main_relief_3d();

    color(accent_color)
        accent_relief_3d();
}

module base_plate_3d() {
    linear_extrude(height = base_thickness)
        base_plate_2d();
}

module combined_relief_3d() {
    union() {
        main_relief_3d();
        accent_relief_3d();
    }
}

module main_relief_3d() {
    translate([0, 0, show_base ? base_thickness - epsilon : 0])
        linear_extrude(height = relief_height + (show_base ? epsilon : 0))
            main_artwork_2d();
}

module accent_relief_3d() {
    translate([0, 0, show_base ? base_thickness - epsilon : 0])
        linear_extrude(height = relief_height + (show_base ? epsilon : 0))
            accent_artwork_2d();
}

module base_plate_2d() {
    rounded_rectangle_2d(base_plate_width, base_plate_height, base_corner_radius);
}

module main_artwork_2d() {
    offset(delta = artwork_offset)
        centered_scaled_svg_2d(main_artwork_svg_path);
}

module accent_artwork_2d() {
    offset(delta = artwork_offset)
        centered_scaled_svg_2d(accent_artwork_svg_path);
}

module centered_scaled_svg_2d(svg_path) {
    scale([artwork_scale_factor, artwork_scale_factor])
        translate([-source_artwork_width / 2, -source_artwork_height / 2])
            import(file = svg_path, dpi = 25.4);
}

module rounded_rectangle_2d(width_mm, height_mm, radius_mm) {
    safe_radius = min(radius_mm, min(width_mm, height_mm) / 2);

    if (safe_radius <= 0) {
        square([width_mm, height_mm], center = true);
    } else {
        offset(r = safe_radius)
            square([width_mm - 2 * safe_radius, height_mm - 2 * safe_radius], center = true);
    }
}
