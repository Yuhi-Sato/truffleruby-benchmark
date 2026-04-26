#!/usr/bin/env bash
# Run every benchmark against rbenv-installed engines (no Docker).
#
# Sister script to run_benchmarks.sh. Use this when you need a current
# TruffleRuby (the docker-hub mirror lags by years) or simply want to
# avoid Docker overhead. Reads the same harness; writes results under
# results/local-<engine>-<bench>.log so the Docker logs are preserved.
set -euo pipefail

cd "$(dirname "$0")"

BENCHES=(binarytrees fannkuchredux nbody)
ENGINES=(yjit zjit truffleruby)

WARMUP_ITERS=${WARMUP_ITERS:-15}
MEASURE_ITERS=${MEASURE_ITERS:-20}

CRUBY_VERSION=${CRUBY_VERSION:-4.0.2}
TRUFFLERUBY_VERSION=${TRUFFLERUBY_VERSION:-truffleruby-33.0.1}

mkdir -p results

ruby_for() {
  case "$1" in
    yjit)        echo "RBENV_VERSION=$CRUBY_VERSION rbenv exec ruby --yjit" ;;
    zjit)        echo "RBENV_VERSION=$CRUBY_VERSION rbenv exec ruby --zjit" ;;
    truffleruby) echo "LANG=en_US.UTF-8 RBENV_VERSION=$TRUFFLERUBY_VERSION rbenv exec ruby" ;;
    *)           echo "unknown engine: $1" >&2; return 1 ;;
  esac
}

verify_engines() {
  echo "==> verifying engines"
  for engine in "${ENGINES[@]}"; do
    cmd=$(ruby_for "$engine")
    printf "  %-12s " "$engine"
    eval "$cmd -e 'puts RUBY_DESCRIPTION'" 2>/dev/null | tail -1
  done
}

run_one() {
  local engine=$1 bench=$2
  local cmd
  cmd=$(ruby_for "$engine")
  local log="results/local-${engine}-${bench}.log"
  echo "==> $engine / $bench"
  WARMUP_ITERS="$WARMUP_ITERS" MEASURE_ITERS="$MEASURE_ITERS" BENCH_NAME="$bench" \
    eval "$cmd benchmarks/${bench}.rb" | tee "$log"
}

verify_engines

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
    log="results/local-${engine}-${bench}.log"
    if [[ -f "$log" ]]; then
      best=$(grep -oE '"best":[0-9.e+-]+' "$log" | head -1 | cut -d: -f2)
      printf "%14s" "${best:-n/a}"
    else
      printf "%14s" "n/a"
    fi
  done
  printf "\n"
done
