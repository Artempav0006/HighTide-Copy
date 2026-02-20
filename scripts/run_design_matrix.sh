#!/usr/bin/env bash
set -euo pipefail

# Example list. You can generate this by "find designs -name config.mk" too.
configs=(
  "designs/nangate45/lfsr_prbs_gen/config.mk"
  "designs/nangate45/minimax/config.mk"
  "designs/nangate45/NyuziProcessor/config.mk"
)

# Determine ORFS docker tag from submodule (similar to your runorfs.sh but non-interactive)
pushd OpenROAD-flow-scripts >/dev/null
tag="$(git describe --tags --abbrev=8 2>/dev/null || true)"
if [ -z "$tag" ]; then
  echo "Warning: ORFS commit not on tag; using fallback."
  tag="v3.0-3201-gf53fbce7"
fi
popd >/dev/null

mkdir -p ci_results

for cfg in "${configs[@]}"; do
  echo "Running design: $cfg"
  safe="$(echo "$cfg" | tr '/' '_' | tr '.' '_')"
  outdir="ci_results/${safe}"
  mkdir -p "$outdir"

  docker run --rm -it \
    -u $(id -u ${USER}):$(id -g ${USER}) \
    -v $(pwd)/flow:/OpenROAD-flow-scripts/flow \
    -v $(pwd)/..:/OpenROAD-flow-scripts/UCSC_ML_suite \
    -w /OpenROAD-flow-scripts/UCSC_ML_suite \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ${HOME}/.Xauthority:/.Xauthority \
    --network host \
    --security-opt seccomp=unconfined \
    openroad/orfs:${tag}
    bash -lc "make DESIGN_CONFIG=/work/$cfg" | tee "$outdir/log.txt"

  # Collect whatever metrics ORFS produces (adjust to your actual outputs)
  # Example: copy results folder if it exists
  if [ -d "results" ]; then
    cp -r results "$outdir/results" || true
  fi
done
