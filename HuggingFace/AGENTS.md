# AGENTS

## Scope

This workspace is a small utility repo for working with the Hugging Face Space `black-forest-labs/flux-klein-9b-kv`.

Current files:
- `flux-klein-generate.sh`: reusable text-to-image generator script
- `trellis-image-to-glb.sh`: image-to-3D GLB generator script
- `flux-klein-to-glb.sh`: tiny wrapper from prompt to GLB
- `FLUX_KLEIN_USAGE.md`: quick usage reference
- `.env`: local environment variables such as `HF_TOKEN`

## Working Rules

- Keep changes minimal and local.
- Prefer simple shell scripts over adding new dependencies.
- Do not commit secrets or copy token values into docs.
- Assume `.env` is local-only and should be read, not rewritten, unless explicitly requested.
- Default to ASCII when editing files.

## Script Conventions

- Keep `flux-klein-generate.sh` runnable as a standalone script.
- Keep `trellis-image-to-glb.sh` runnable as a standalone script.
- Keep `flux-klein-to-glb.sh` as a thin wrapper over the other two scripts.
- Preserve support for loading `HF_TOKEN` from `.env` when not already exported.
- Prefer stable CLI flags over breaking interface changes.
- If adding features, keep the text-to-image and image-to-GLB paths straightforward and avoid unnecessary abstraction.

## Verification

For script changes, run:

```bash
bash -n "flux-klein-generate.sh"
./flux-klein-generate.sh --help
bash -n "trellis-image-to-glb.sh"
./trellis-image-to-glb.sh --help
bash -n "flux-klein-to-glb.sh"
./flux-klein-to-glb.sh --help
```

If the change affects generation behavior, also run a small smoke test such as:

```bash
./flux-klein-generate.sh --width 256 --height 256 --steps 1 --output "test.webp" "red square"
./trellis-image-to-glb.sh --output "test.glb" "test.webp"
```

## Documentation

- Keep `FLUX_KLEIN_USAGE.md` in sync with CLI behavior.
- Document only the common path unless more detail is clearly needed.
