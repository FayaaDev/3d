# OpenSCAD Workflow Entry Point

Always load and follow the `openscad` skill before classifying a source, choosing a conversion pathway, creating or reviewing a final `.scad` wrapper, generating previews, exporting STL files, or assessing slicer readiness.

For raster artwork, logos, calligraphy, and similar image inputs that need to become
OpenSCAD-importable SVGs, use the local `inkscape` skill as the cleanup and
tracing workflow before importing into OpenSCAD.

When the source is a noisy or low-contrast raster, use ImageMagick first to
prepare a cleaner monochrome mask by thresholding, flattening transparency,
cropping, resizing, or boosting contrast as needed.

When the source is a high-contrast bitmap silhouette or logo, use `potrace` when
it is the fastest way to generate clean vector paths before the Inkscape cleanup
pass.

That raster-to-vector preparation should produce:
- use ImageMagick only for preprocessing, not as the final editable vector step
- use `potrace` for monochrome bitmap-to-path conversion when it improves speed or fidelity
- trace the bitmap into vector paths
- delete the original embedded bitmap from the SVG
- keep only clean filled vector geometry
- fit the page to the drawing or selection so bounds are predictable
- export a plain SVG that OpenSCAD can import cleanly
- break apart the SVG to pieces

Prefer a single-color vector-only SVG when the traced color separation introduces edge
halos or overlapping artifacts that would hurt OpenSCAD import quality.

Do not infer the image-to-model workflow from this file. If this file and the `openscad` skill ever conflict, the `openscad` skill wins.
