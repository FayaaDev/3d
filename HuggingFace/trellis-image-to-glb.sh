#!/usr/bin/env bash

set -euo pipefail

SPACE_ROOT="https://microsoft-trellis-2.hf.space"
API_ROOT="$SPACE_ROOT/gradio_api"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

resolution="512"
seed=0
randomize_seed=true
decimation_target=300000
texture_size=2048
output_path=""
print_json=false
debug=false
input_path=""

usage() {
  cat <<'EOF'
Usage: ./trellis-image-to-glb.sh [options] /path/to/image.webp

Options:
  -o, --output PATH             Save GLB to PATH
  --resolution VALUE        512, 1024, or 1536 (default: 512)
  --seed N                  Seed value (default: 0)
      --no-randomize-seed       Use the provided seed as-is
  --decimation-target N     Mesh decimation target (default: 300000)
  --texture-size N          Texture size (default: 2048)
  --json                    Print final result JSON to stdout
      --debug                   Print raw TRELLIS stage payloads to stderr
  -h, --help                    Show this help

If HF_TOKEN is not already exported, the script will try to load it from
./.env next to the script.
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

queue_join() {
  local payload="$1"
  "${curl_args[@]}" -X POST "$API_ROOT/queue/join" -H "Content-Type: application/json" -d "$payload"
}

compact_json() {
  printf '%s' "$1" | jq -c '.'
}

queue_wait() {
  local stage="$1"
  local session_hash="$2"
  local json_path="$3"
  local stream
  local completed

  stream="$("${curl_args[@]}" -N "$API_ROOT/queue/data?session_hash=$session_hash")"
  completed="$(printf '%s\n' "$stream" | awk '/^data: / && /"msg":"process_completed"/{line=$0} END{sub(/^data: /, "", line); print line}')"
  [[ -n "$completed" ]] || fail "did not receive process_completed payload"

  if [[ -n "$json_path" ]]; then
    printf '%s\n' "$completed" > "$json_path"
  fi

  if [[ "$debug" == true ]]; then
    printf 'TRELLIS %s: %s\n' "$stage" "$(compact_json "$completed")" >&2
  fi

  if [[ "$(printf '%s' "$completed" | jq -r '.success')" != "true" ]]; then
    fail "$stage failed: $(printf '%s' "$completed" | jq -r '.output.error // .title // "TRELLIS request failed"')"
  fi

  printf '%s' "$completed"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)
      [[ $# -ge 2 ]] || fail "missing value for $1"
      output_path="$2"
      shift 2
      ;;
    --resolution)
      [[ $# -ge 2 ]] || fail "missing value for $1"
      resolution="$2"
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
    --decimation-target)
      [[ $# -ge 2 ]] || fail "missing value for $1"
      decimation_target="$2"
      shift 2
      ;;
    --texture-size)
      [[ $# -ge 2 ]] || fail "missing value for $1"
      texture_size="$2"
      shift 2
      ;;
    --json)
      print_json=true
      shift
      ;;
    --debug)
      debug=true
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

if [[ $# -ne 1 ]]; then
  fail "exactly one input image path is required"
fi

input_path="$1"
[[ -f "$input_path" ]] || fail "input image does not exist: $input_path"

require_number "seed" "$seed"
require_number "decimation target" "$decimation_target"
require_number "texture size" "$texture_size"

case "$resolution" in
  512|1024|1536) ;;
  *) fail "resolution must be one of: 512, 1024, 1536" ;;
esac

if [[ -z "${HF_TOKEN:-}" && -f "$SCRIPT_DIR/.env" ]]; then
  set -a
  . "$SCRIPT_DIR/.env"
  set +a
fi

curl_args=(curl -fsS)
if [[ -n "${HF_TOKEN:-}" ]]; then
  curl_args+=(-H "Authorization: Bearer $HF_TOKEN")
fi

config="$("${curl_args[@]}" "$SPACE_ROOT/config")"
start_fn="$(printf '%s' "$config" | jq -r '.dependencies[] | select(.api_name=="start_session") | .id')"
preprocess_fn="$(printf '%s' "$config" | jq -r '.dependencies[] | select(.api_name=="preprocess_image") | .id')"
seed_fn="$(printf '%s' "$config" | jq -r '.dependencies[] | select(.api_name=="get_seed") | .id')"
prepare_image_fn="$(printf '%s' "$config" | jq -r '.dependencies[] | select(.api_name=="lambda") | .id')"
image_fn="$(printf '%s' "$config" | jq -r '.dependencies[] | select(.api_name=="image_to_3d") | .id')"
extract_fn="$(printf '%s' "$config" | jq -r '.dependencies[] | select(.api_name=="extract_glb") | .id')"
prepare_extract_fn="$(printf '%s' "$config" | jq -r '.dependencies[] | select(.api_name=="lambda_1") | .id')"

[[ -n "$start_fn" && -n "$preprocess_fn" && -n "$seed_fn" && -n "$prepare_image_fn" && -n "$image_fn" && -n "$extract_fn" && -n "$prepare_extract_fn" ]] || fail "could not resolve TRELLIS endpoint ids"

session_hash="$(uuidgen | tr 'A-Z' 'a-z' | tr -d '-')"
upload_path="$("${curl_args[@]}" -X POST "$API_ROOT/upload" -F "files=@$input_path" | jq -r '.[0] // empty')"
[[ -n "$upload_path" ]] || fail "image upload did not return a server path"
upload_url="$SPACE_ROOT/gradio_api/file=$upload_path"
upload_size="$(wc -c < "$input_path" | tr -d '[:space:]')"
mime_type="$(file --brief --mime-type "$input_path" 2>/dev/null || printf 'application/octet-stream')"

start_payload="$(jq -nc --arg session_hash "$session_hash" --argjson fn_index "$start_fn" '{data:[], fn_index:$fn_index, session_hash:$session_hash}')"
queue_join "$start_payload" >/dev/null
queue_wait "start_session" "$session_hash" "" >/dev/null

preprocess_payload="$(jq -nc \
  --arg path "$upload_path" \
  --arg url "$upload_url" \
  --arg name "$(basename -- "$input_path")" \
  --arg mime_type "$mime_type" \
  --arg session_hash "$session_hash" \
  --argjson fn_index "$preprocess_fn" \
  --argjson size "$upload_size" \
  '{
    data: [
      {
        path: $path,
        url: $url,
        orig_name: $name,
        size: $size,
        mime_type: $mime_type,
        meta: {_type: "gradio.FileData"}
      }
    ],
    fn_index: $fn_index,
    trigger_id: 4,
    session_hash: $session_hash
  }')"

queue_join "$preprocess_payload" >/dev/null
preprocess_result="$(queue_wait "preprocess_image" "$session_hash" "")"
processed_image="$(printf '%s' "$preprocess_result" | jq -c '.output.data[0] // empty')"
[[ -n "$processed_image" ]] || fail "preprocess_image did not return an image"

seed_payload="$(jq -nc \
  --arg session_hash "$session_hash" \
  --argjson fn_index "$seed_fn" \
  --argjson randomize_seed "$randomize_seed" \
  --argjson seed "$seed" \
  '{data: [$randomize_seed, $seed], fn_index: $fn_index, trigger_id: 10, session_hash: $session_hash}')"

queue_join "$seed_payload" >/dev/null
seed_result="$(queue_wait "get_seed" "$session_hash" "")"
effective_seed="$(printf '%s' "$seed_result" | jq -r '.output.data[0] // empty')"
[[ -n "$effective_seed" ]] || fail "get_seed did not return a seed"

prepare_image_payload="$(jq -nc \
  --arg session_hash "$session_hash" \
  --argjson fn_index "$prepare_image_fn" \
  '{data: [], event_data: null, fn_index: $fn_index, trigger_id: 10, session_hash: $session_hash}')"

queue_join "$prepare_image_payload" >/dev/null
queue_wait "prepare_image" "$session_hash" "" >/dev/null

image_payload="$(jq -nc \
  --argjson image "$processed_image" \
  --arg resolution "$resolution" \
  --arg session_hash "$session_hash" \
  --argjson fn_index "$image_fn" \
  --argjson seed "$effective_seed" \
  '{
    data: [
      $image,
      $seed,
      $resolution,
      7.5,
      0.7,
      12,
      5.0,
      7.5,
      0.5,
      12,
      3.0,
      1.0,
      0.0,
      12,
      3.0
    ],
    event_data: null,
    fn_index: $fn_index,
    trigger_id: 10,
    session_hash: $session_hash
  }')"

printf 'Started TRELLIS image_to_3d session %s\n' "$session_hash" >&2
queue_join "$image_payload" >/dev/null
image_result="$(queue_wait "image_to_3d" "$session_hash" "")"

prepare_extract_payload="$(jq -nc \
  --arg session_hash "$session_hash" \
  --argjson fn_index "$prepare_extract_fn" \
  '{data: [], fn_index: $fn_index, trigger_id: 38, session_hash: $session_hash}')"

queue_join "$prepare_extract_payload" >/dev/null
queue_wait "prepare_extract" "$session_hash" "" >/dev/null

extract_payload="$(jq -nc \
  --arg session_hash "$session_hash" \
  --argjson fn_index "$extract_fn" \
  --argjson decimation_target "$decimation_target" \
  --argjson texture_size "$texture_size" \
  '{
    data: [null, $decimation_target, $texture_size],
    event_data: null,
    fn_index: $fn_index,
    trigger_id: 38,
    session_hash: $session_hash
  }')"

printf 'Extracting GLB\n' >&2
queue_join "$extract_payload" >/dev/null
extract_result="$(queue_wait "extract_glb" "$session_hash" "")"

glb_url="$(printf '%s' "$extract_result" | jq -r '.output.data[1].url // .output.data[0].url // empty')"
glb_name="$(printf '%s' "$extract_result" | jq -r '.output.data[1].orig_name // .output.data[0].orig_name // "model.glb"')"
[[ -n "$glb_url" ]] || fail "extract_glb did not return a GLB URL"

if [[ -z "$output_path" ]]; then
  mkdir -p "$SCRIPT_DIR/outputs"
  output_path="$SCRIPT_DIR/outputs/${glb_name}"
fi

"${curl_args[@]}" "$glb_url" -o "$output_path"

printf 'Saved GLB to %s\n' "$output_path" >&2

if [[ "$print_json" == true ]]; then
  jq -nc \
    --arg input_path "$input_path" \
    --arg output_path "$output_path" \
    --arg glb_url "$glb_url" \
    --arg session_hash "$session_hash" \
    --argjson image_result "$image_result" \
    --argjson extract_result "$extract_result" \
    '{input_path: $input_path, output_path: $output_path, glb_url: $glb_url, session_hash: $session_hash, image_result: $image_result, extract_result: $extract_result}'
fi
