#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

image_args=()
glb_args=()
glb_output=""
seen_separator=false

usage() {
  cat <<'EOF'
Usage: ./flux-klein-to-glb.sh [image options] [--glb-output PATH] -- [glb options] -- "your prompt"

Examples:
  ./flux-klein-to-glb.sh -- -- "a glossy red toy robot"
  ./flux-klein-to-glb.sh --output "outputs/robot.webp" --glb-output "outputs/robot.glb" -- -- "a glossy red toy robot"
  ./flux-klein-to-glb.sh --width 512 --height 512 --steps 4 -- --resolution 512 -- "a glossy red toy robot"

Behavior:
  - arguments before the first -- are passed to flux-klein-generate.sh
  - arguments between the first -- and final prompt are passed to trellis-image-to-glb.sh
  - --glb-output PATH is handled by this wrapper and forwarded as -o PATH to trellis-image-to-glb.sh
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --glb-output)
      [[ $# -ge 2 ]] || fail "missing value for $1"
      glb_output="$2"
      shift 2
      ;;
    --)
      if [[ "$seen_separator" == false ]]; then
        seen_separator=true
        shift
        continue
      fi
      shift
      break
      ;;
    *)
      if [[ "$seen_separator" == false ]]; then
        image_args+=("$1")
      else
        glb_args+=("$1")
      fi
      shift
      ;;
  esac
done

[[ $# -gt 0 ]] || fail "prompt is required after the final --"

prompt="$*"

if [[ -n "$glb_output" ]]; then
  glb_args+=(-o "$glb_output")
fi

image_json="$("$SCRIPT_DIR/flux-klein-generate.sh" --json "${image_args[@]}" "$prompt")"
image_path="$(printf '%s' "$image_json" | jq -r '.output_path // empty')"
[[ -n "$image_path" ]] || fail "image generation did not return an output path"

printf 'Generated image %s\n' "$image_path" >&2
"$SCRIPT_DIR/trellis-image-to-glb.sh" "${glb_args[@]}" "$image_path"
