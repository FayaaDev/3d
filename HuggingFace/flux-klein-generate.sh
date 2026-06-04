#!/usr/bin/env bash

set -euo pipefail

SPACE_ROOT="https://black-forest-labs-flux-klein-9b-kv.hf.space"
API_ROOT="$SPACE_ROOT/gradio_api/call"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

width=1024
height=1024
steps=4
seed=0
randomize_seed=true
prompt_upsampling=false
output_path=""
print_json=false
prompt=""

usage() {
  cat <<'EOF'
Usage: ./flux-klein-generate.sh [options] "your prompt"

Options:
  -o, --output PATH          Save image to PATH
      --width N              Output width (256-1024, default: 1024)
      --height N             Output height (256-1024, default: 1024)
      --steps N              Inference steps (1-20, default: 4)
      --seed N               Seed value (default: 0)
      --no-randomize-seed    Use the provided seed as-is
      --prompt-upsampling    Enable prompt upsampling
      --json                 Print final result JSON to stdout
  -h, --help                 Show this help

If HF_TOKEN is not already exported, the script will try to load it from
./.env next to the script. The token is optional for this public endpoint.
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

require_number() {
  case "$2" in
    ''|*[!0-9]*) fail "$1 must be an integer" ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)
      [[ $# -ge 2 ]] || fail "missing value for $1"
      output_path="$2"
      shift 2
      ;;
    --width)
      [[ $# -ge 2 ]] || fail "missing value for $1"
      width="$2"
      shift 2
      ;;
    --height)
      [[ $# -ge 2 ]] || fail "missing value for $1"
      height="$2"
      shift 2
      ;;
    --steps)
      [[ $# -ge 2 ]] || fail "missing value for $1"
      steps="$2"
      shift 2
      ;;
    --seed)
      [[ $# -ge 2 ]] || fail "missing value for $1"
      seed="$2"
      shift 2
      ;;
    --no-randomize-seed)
      randomize_seed=false
      shift
      ;;
    --prompt-upsampling)
      prompt_upsampling=true
      shift
      ;;
    --json)
      print_json=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      fail "unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -eq 0 ]]; then
  fail "prompt is required"
fi

prompt="$*"

require_number "width" "$width"
require_number "height" "$height"
require_number "steps" "$steps"
require_number "seed" "$seed"

if [[ -z "${HF_TOKEN:-}" && -f "$SCRIPT_DIR/.env" ]]; then
  set -a
  . "$SCRIPT_DIR/.env"
  set +a
fi

curl_args=(curl -fsS)
if [[ -n "${HF_TOKEN:-}" ]]; then
  curl_args+=(-H "Authorization: Bearer $HF_TOKEN")
fi

payload="$({
  jq -nc \
    --arg prompt "$prompt" \
    --argjson seed "$seed" \
    --argjson randomize_seed "$randomize_seed" \
    --argjson width "$width" \
    --argjson height "$height" \
    --argjson steps "$steps" \
    --argjson prompt_upsampling "$prompt_upsampling" \
    '{data: [$prompt, [], $seed, $randomize_seed, $width, $height, $steps, $prompt_upsampling]}'
})"

event_id="$("${curl_args[@]}" -X POST "$API_ROOT/generate" -H "Content-Type: application/json" -d "$payload" | jq -r '.event_id // empty')"
[[ -n "$event_id" ]] || fail "did not receive event_id from Space"

printf 'Started job %s\n' "$event_id" >&2

stream="$("${curl_args[@]}" -N "$API_ROOT/generate/$event_id")"
result_json="$(printf '%s\n' "$stream" | awk '/^data: /{line=$0} END{sub(/^data: /, "", line); print line}')"
[[ -n "$result_json" ]] || fail "did not receive result payload"

image_url="$(printf '%s' "$result_json" | jq -r '.[0].url // empty')"
image_name="$(printf '%s' "$result_json" | jq -r '.[0].orig_name // "image.webp"')"
final_seed="$(printf '%s' "$result_json" | jq -r '.[1]')"

[[ -n "$image_url" ]] || fail "result did not include an image URL"

if [[ -z "$output_path" ]]; then
  mkdir -p "$SCRIPT_DIR/outputs"
  output_path="$SCRIPT_DIR/outputs/${final_seed}-${image_name}"
fi

"${curl_args[@]}" "$image_url" -o "$output_path"

printf 'Saved image to %s\n' "$output_path" >&2
printf 'Seed: %s\n' "$final_seed" >&2

if [[ "$print_json" == true ]]; then
  jq -nc \
    --arg output_path "$output_path" \
    --arg image_url "$image_url" \
    --argjson seed "$final_seed" \
    --argjson result "$result_json" \
    '{output_path: $output_path, image_url: $image_url, seed: $seed, result: $result}'
fi
