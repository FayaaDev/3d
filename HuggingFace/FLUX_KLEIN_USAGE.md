# FLUX Klein Usage

Generate an image from a text prompt with `flux-klein-generate.sh`.

Convert a generated image into a 3D `GLB` with `trellis-image-to-glb.sh`.

Or run the full prompt-to-GLB flow with `flux-klein-to-glb.sh`.

## Basic

```bash
./flux-klein-generate.sh "a cinematic photo of a neon-lit alley in Tokyo at night"
```

This saves the image to `./outputs/<seed>-image.webp` by default.

## Save To A Specific File

```bash
./flux-klein-generate.sh \
  --output "tokyo.webp" \
  "a cinematic photo of a neon-lit alley in Tokyo at night"
```

## Common Options

```bash
./flux-klein-generate.sh \
  --width 768 \
  --height 768 \
  --steps 4 \
  --seed 12345 \
  --no-randomize-seed \
  --prompt-upsampling \
  --json \
  "a cinematic photo of a neon-lit alley in Tokyo at night"
```

## Notes

- The script loads `HF_TOKEN` from `.env` if it is present.
- `HF_TOKEN` is optional for this public Space, but the script will send it when available.
- Run `./flux-klein-generate.sh --help` to see all flags.

## Image To GLB

Convert an existing image into a 3D model:

```bash
./trellis-image-to-glb.sh "outputs/1597496325-image.webp"
```

Save the `GLB` to a specific file:

```bash
./trellis-image-to-glb.sh \
  --resolution 512 \
  --output "outputs/model.glb" \
  "outputs/1597496325-image.webp"
```

## Prompt To GLB

Generate an image first, then convert it to `GLB`:

```bash
IMAGE_PATH="$(./flux-klein-generate.sh --json "a glossy red toy robot" | jq -r '.output_path')"
./trellis-image-to-glb.sh "$IMAGE_PATH"
```

One-command wrapper:

```bash
./flux-klein-to-glb.sh -- \
  --resolution 512 \
  -- \
  "a glossy red toy robot"
```

Save both the intermediate image and final `GLB`:

```bash
./flux-klein-to-glb.sh \
  --output "outputs/robot.webp" \
  --glb-output "outputs/robot.glb" \
  -- \
  --resolution 512 \
  -- \
  "a glossy red toy robot"
```

## TRELLIS Notes

- `trellis-image-to-glb.sh` loads `HF_TOKEN` from `.env` when available.
- The output is a `GLB` asset, which is suitable as the next step before mesh cleanup or 3D printing prep.
- Run `./trellis-image-to-glb.sh --help` to see all flags.
