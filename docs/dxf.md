# DXF Relief Model Notes

## Source Files

- Input DXF: `openscad/models/img.dxf`
- Editable OpenSCAD wrapper: `openscad/models/img_relief_from_dxf.scad`
- Generated OpenSCAD polygon geometry: `openscad/models/img_dxf_geometry.scad`
- Exported STL: `openscad/exports/img_relief_from_dxf.stl`
- Printable thickened test STL: `openscad/exports/img_relief_from_dxf_printable_offset.stl`
- Preview images: `openscad/exports/img_relief_from_dxf_previews/`

## Goal

Create a printable 3D model from `img.dxf` by turning the 2D vector artwork into a raised-relief plaque. The resulting model keeps the original DXF trace editable through OpenSCAD parameters instead of baking all dimensions into the STL.

## What Was Created

`img_relief_from_dxf.scad` is the main model file. It builds a rectangular rounded backing plate and places the DXF artwork on top as raised geometry.

The file exposes these main parameters:

- `target_width`: final artwork width in millimeters, default `120`.
- `base_margin`: border around the artwork, default `4`.
- `base_thickness`: backing plate thickness, default `2.0`.
- `relief_height`: raised artwork height, default `2.4`.
- `base_corner_radius`: rounded plate corner radius, default `3`.
- `artwork_offset`: grow or shrink the artwork contours, default `0.0`.
- `show_base`: toggles the backing plate.

The wrapper uses `img_dxf_geometry.scad`, scales the original DXF drawing units into millimeters, centers the artwork, and extrudes it above the base.

## Conversion Workflow

The DXF was inspected first to understand its structure. It contains 34 closed `POLYLINE` contours, 1260 original vertices, and a measured drawing bounds of approximately:

- Minimum X: `301.210073`
- Minimum Y: `177.000000`
- Width: `597.660236`
- Depth: `275.984687`

The first attempt used OpenSCAD's direct DXF import:

```scad
import(file = "img.dxf", convexity = 10);
```

OpenSCAD validated the wrapper, but during export it warned that the old DXF entities were unsupported:

```text
WARNING: Unsupported DXF Entity 'SEQEND'
WARNING: Unsupported DXF Entity 'VERTEX'
WARNING: Unsupported DXF Entity 'POLYLINE'
```

That meant OpenSCAD ignored the actual artwork and exported mostly the backing plate. To fix this, the DXF was converted into native OpenSCAD polygons.

The conversion step parsed the old DXF group-code format, extracted each polyline vertex, expanded DXF `bulge` arc values into short line segments, detected contour nesting for holes, and wrote the generated geometry to `img_dxf_geometry.scad` as `polygon()` calls.

The final wrapper uses:

```scad
use <img_dxf_geometry.scad>
```

and calls:

```scad
img_dxf_artwork_2d();
```

inside `linear_extrude()`.

`img_dxf_geometry.scad` also includes a small top-level preview extrusion so it can be opened directly in OpenSCAD. The main wrapper uses `use` instead of `include`, so that standalone preview geometry is ignored when generating the final plaque.

## Challenges

- The DXF is an older `AC1006` style file using `POLYLINE`, `VERTEX`, and `SEQEND` records.
- OpenSCAD's DXF importer did not support those records in this file, so direct import did not preserve the artwork.
- The DXF used bulge values to describe curved segments, so simply reading X/Y vertices would have lost curved detail.
- The file contained many separate closed contours rather than one simple outline.
- Some details in the artwork are extremely small after scaling to `120 mm` wide.
- A few contours are holes inside larger contours, so treating every contour as a filled shape would have filled details that should remain open.

## Solutions

- Converted the DXF to native OpenSCAD geometry instead of relying on `import()`.
- Expanded bulge arcs into polygon points using a small angle step so curves remain smooth enough for a relief model.
- Calculated the source bounding box from all closed contours and used it for predictable scaling.
- Detected parent and child contours so nested contours can be subtracted as holes.
- Kept the generated polygon data in a separate file so the main `.scad` file stays readable and parametric.
- Added `artwork_offset`, which lets the artwork be thickened or thinned in real millimeters even though the source geometry is still in DXF drawing units.
- Added a small `epsilon` overlap between the relief and base to avoid coincident-face problems during boolean/render operations.

## Validation Results

OpenSCAD syntax validation succeeded for `img_relief_from_dxf.scad`.

The main STL exported successfully:

```text
Top level object is a 3D object (manifold)
Status: NoError
Vertices: 9632
Facets: 19260
```

A second STL was exported with a safer detail offset:

```bash
./.agents/skills/openscad/tools/export-stl.sh "models/img_relief_from_dxf.scad" "exports/img_relief_from_dxf_printable_offset.stl" -D "artwork_offset=0.2"
```

Multi-angle previews were generated and visually checked from isometric, top, and side views. The model appears as a flat rounded plaque with raised black artwork on top.

## Printability Notes

- The default model is suitable as a decorative raised-relief plaque.
- The default size is roughly `128 x 63.4 x 4.4 mm`, including the base margin and relief height.
- Some of the smallest DXF details may be too thin for reliable FDM printing at the default scale.
- For FDM printing, use `artwork_offset=0.2` or larger, or increase `target_width`.
- The STL should still be checked in OrcaSlicer before printing, especially layer preview, minimum wall paths, and tiny raised features.

## Preparing Future Artwork

The best way to avoid extra conversion work is to provide vector geometry instead of a raster image or an old DXF. The cleanest input is an `SVG` with filled, closed paths.

Best input formats:

- `SVG` with filled closed paths.
- Modern `DXF` with closed `LWPOLYLINE` entities.
- Native OpenSCAD `polygon()` data or a reusable `module artwork_2d()`.

Avoid these inputs when possible:

- Old `AC1006` DXF files.
- DXF files using `POLYLINE`, `VERTEX`, and `SEQEND` entities.
- Open paths that do not form closed printable regions.
- Thin strokes that have not been converted to filled shapes.
- Anti-aliased raster images as the only source.
- Tiny disconnected islands unless they are intentionally part of the final print.

If starting from a raster image, prepare it like this before conversion:

- Use black artwork on a white or transparent background.
- Use high resolution, ideally `1000 px` wide or larger.
- Remove shadows, gradients, blur, texture, and anti-alias fuzz.
- Make the artwork solid silhouettes rather than outlines.
- Avoid details thinner than about `1.5 mm` to `2 mm` at the final print size.
- Vectorize the image to `SVG`.
- In Inkscape, Illustrator, or similar software, convert strokes to paths.
- Simplify paths moderately without destroying the intended shape.
- Save as plain `SVG` when possible.

If exporting DXF, use a newer format and closed contours:

- Prefer `DXF R14` or newer.
- Use closed `LWPOLYLINE` entities rather than old `POLYLINE` / `VERTEX` records.
- Flatten curves if the target CAD/import tool has trouble with splines or arcs.
- Keep units in millimeters when possible.
- Make sure holes are closed inner contours.
- Put the artwork on one layer when possible.

Ideal future request format:

```text
Use this SVG as raised artwork.
Final width: 120 mm.
Base thickness: 2 mm.
Relief height: 2.4 mm.
Make details FDM-printable.
```

## Future Improvements

- Move the one-off DXF conversion logic into a reusable script under `openscad/.agents/skills/openscad/tools/` or another project tools folder.
- Add OpenSCAD Customizer section headings such as `/* [Artwork] */`, `/* [Base] */`, and `/* [Printability] */`.
- Add a `target_height` option in addition to `target_width` for alternate sizing workflows.
- Add optional hanger holes, magnet pockets, or screw slots to make the plaque mountable.
- Add an optional two-color layout by exporting base and relief as separate STL parts.
- Simplify or decimate tiny noisy contours for cleaner slicing and smaller STL files.
- Add a parameter preset for FDM-safe minimum detail thickness.
- Run the exported STL through OrcaSlicer and save a `.3mf` project with validated orientation and slicing settings.
