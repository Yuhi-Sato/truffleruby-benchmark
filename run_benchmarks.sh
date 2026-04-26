#!/usr/bin/env bash
# Build the three engine images and run every benchmark against each.
# Results land in results/<engine>-<benchmark>.log.
set -euo pipefail

cd "$(dirname "$0")"

BENCHES=(binarytrees fannkuchredux nbody)
ENGINES=(yjit zjit truffleruby)

WARMUP_ITERS=${WARMUP_ITERS:-5}
MEASURE_ITERS=${MEASURE_ITERS:-10}

mkdir -p results

build_image() {
  local engine=$1
  local tag="ruby-bench-$engine"
  echo "==> building $tag"
  docker build -f "docker/Dockerfile.$engine" -t "$tag" .
}

run_one() {
  local engine=$1 bench=$2
  local tag="ruby-bench-$engine"
  local log="results/${engine}-${bench}.log"
  echo "==> $engine / $bench"
  docker run --rm \
    -e WARMUP_ITERS="$WARMUP_ITERS" \
    -e MEASURE_ITERS="$MEASURE_ITERS" \
    -e BENCH_NAME="$bench" \
    "$tag" ruby "benchmarks/${bench}.rb" \
    | tee "$log"
}

for engine in "${ENGINES[@]}"; do
  build_image "$engine"
done

for engine in "${ENGINES[@]}"; do
  for bench in "${BENCHES[@]}"; do
    run_one "$engine" "$bench" || echo "FAILED: $engine/$bench"
  done
done

echo
echo "=== summary (best-of-$MEASURE_ITERS, lower is better) ==="
printf "%-16s" "benchmark"
for engine in "${ENGINES[@]}"; do printf "%14s" "$engine"; done
printf "\n"
for bench in "${BENCHES[@]}"; do
  printf "%-16s" "$bench"
  for engine in "${ENGINES[@]}"; do
    log="results/${engine}-${bench}.log"
    if [[ -f "$log" ]]; then
      best=$(grep -oE '"best":[0-9.]+' "$log" | head -1 | cut -d: -f2)
      printf "%14s" "${best:-n/a}"
    else
      printf "%14s" "n/a"
    fi
  done
  printf "\n"
done
