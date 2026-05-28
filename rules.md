# OpenSCAD Workflow Entry Point

The local `openscad` skill is the canonical workflow authority for this repo's OpenSCAD model work.

Always load and follow the `openscad` skill before classifying a source, choosing a conversion pathway, creating or reviewing a final `.scad` wrapper, generating previews, exporting STL files, or assessing slicer readiness.

For raster artwork, logos, calligraphy, and similar image inputs that need to become
OpenSCAD-importable SVGs, use the local `cli-anything-inkscape` skill as the cleanup
and tracing workflow before importing into OpenSCAD.

That Inkscape step should produce the same kind of result used for `test.png`:
- trace the bitmap into vector paths
- delete the original embedded bitmap from the SVG
- keep only clean filled vector geometry
- fit the page to the drawing or selection so bounds are predictable
- export a plain SVG that OpenSCAD can import cleanly

Prefer a single-color vector-only SVG when the traced color separation introduces edge
halos or overlapping artifacts that would hurt OpenSCAD import quality.

Do not infer the image-to-model workflow from this file. If this file and the `openscad` skill ever conflict, the `openscad` skill wins.
