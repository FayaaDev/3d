# Image To 3D Usage

This folder contains two standalone image-to-3D scripts:

- `sparc3d.sh` converts an existing image into `GLB`, `OBJ`, or `STL`.
- `hunyuan3d.sh` converts an existing image into `GLB`, `OBJ`, `PLY`, or `STL`.

## Sparc3D

Convert an existing image into a model with Sparc3D:

```bash
./sparc3d.sh "outputs/robot.webp"
```

Choose another format and output path:

```bash
./sparc3d.sh \
  --format stl \
  --output "outputs/robot.stl" \
  "outputs/robot.webp"
```

Check Sparc3D JobId Status
```
curl -fsS \
  -H "appid: 20009406" \
  -H "huggingface: 1" \
  "https://3dserver.hitem3d.ai/aigc/api/generate/result?jobId=<JOBIDHERE>" | jq
```

## Sparc3D Notes

## Hunyuan3D

Convert an existing image into a model with Hunyuan3D:

```bash
./hunyuan3d.sh "outputs/robot.webp"
```

Choose another format and output path:

```bash
./hunyuan3d.sh \
  --format stl \
  --output "outputs/robot.stl" \
  "outputs/robot.webp"
```

## Notes

`./sparc3d.sh --help` or `./hunyuan3d.sh --help` to see all flags.
