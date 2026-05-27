# Potrace Cheatcode

## PNG to SVG on macOS

`potrace` and `mkbitmap` do not read PNG directly. Use macOS `sips` to convert the PNG to BMP first.

```bash
sips -s format bmp input.png --out input.bmp
mkbitmap input.bmp -o input.pbm
potrace input.pbm -s --tight -o output.svg
```

## Bitmap to SVG

Use this when your input is already in a supported bitmap format.

```bash
mkbitmap input.png -o input.pbm
potrace input.pbm -s -o output.svg
```

Note: `mkbitmap input.png` only works if your `mkbitmap` build supports PNG. The Homebrew/macOS Potrace tools usually support `pnm` and `bmp`, so use the `sips` workflow above for PNG files.
