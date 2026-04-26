# Ruby JIT Benchmark: YJIT vs ZJIT vs TruffleRuby

A reproduction of [Eregon's 2022 Ruby JIT shootout](https://eregon.me/blog/2022/01/06/benchmarking-cruby-mjit-yjit-jruby-truffleruby.html)
brought forward to **Ruby 4.0.2** (released 2026-03-16) so we can include the
new **ZJIT** compiler that landed in Ruby 4.0 alongside the existing **YJIT**
and **TruffleRuby**.

Each Ruby implementation is run inside its own Docker image so the comparison
is reproducible and isolated from the host toolchain.

## Layout

```
benchmarks/                 standalone Ruby benchmarks (no external harness)
  harness.rb                shared warmup + timing harness
  binarytrees.rb            Computer Language Benchmarks Game
  fannkuchredux.rb          Computer Language Benchmarks Game
  nbody.rb                  Computer Language Benchmarks Game
docker/
  Dockerfile.yjit           ruby:4.0.2-slim + RUBYOPT=--yjit
  Dockerfile.zjit           ruby:4.0.2-slim + RUBYOPT=--zjit
  Dockerfile.truffleruby    ghcr.io/oracle/truffleruby:stable
run_benchmarks.sh           build all images, run every benchmark, print table
results/                    populated by run_benchmarks.sh
```

The benchmarks are adapted from [Shopify/yjit-bench](https://github.com/Shopify/yjit-bench)
but stripped of the `harness/loader` dependency so they run unmodified on
TruffleRuby. Algorithms and inputs are unchanged.

## Usage

```bash
# Build the three images and run every benchmark on each.
./run_benchmarks.sh

# Tune iteration counts (defaults: 5 warmup, 10 measured).
WARMUP_ITERS=10 MEASURE_ITERS=20 ./run_benchmarks.sh
```

Each engine/benchmark pair produces `results/<engine>-<benchmark>.log` with one
JSON-shaped `RESULT { ... }` line. The driver prints a best-time summary table
at the end.

### Run a single combination

```bash
docker build -f docker/Dockerfile.yjit -t ruby-bench-yjit .
docker run --rm -e BENCH_NAME=nbody ruby-bench-yjit ruby benchmarks/nbody.rb
```

## What's being measured

The harness runs the workload `WARMUP_ITERS` times (discarded — these allow
each JIT to reach steady state) then `MEASURE_ITERS` times for measurement,
reporting best / worst / mean / stddev wall-clock time per iteration via
`Process::CLOCK_MONOTONIC`.

Why best-of-N rather than mean? JITs warm up monotonically; the mean drags in
warmup-tail noise. Eregon's post and yjit-bench both report best-of-N for the
same reason.

## Engines under test

| Engine       | Ruby version      | JIT flag          | Notes                                                |
|--------------|-------------------|-------------------|------------------------------------------------------|
| YJIT         | CRuby 4.0.2       | `--yjit`          | Lazy basic-block versioning, production default      |
| ZJIT         | CRuby 4.0.2       | `--zjit`          | New method-based JIT introduced in 4.0, experimental |
| TruffleRuby  | latest stable     | (always JITted)   | GraalVM-based; Native image by default               |

ZJIT is experimental in 4.0 — the upstream goal is to make it surpass YJIT in
4.1. Expect ZJIT to be slower than YJIT on most of these workloads today.

## Caveats

- Docker on macOS / Windows runs through a VM; numbers there are not
  comparable to bare-metal Linux. Run on Linux for trustworthy figures.
- TruffleRuby's first iteration is dominated by warmup. Bump `WARMUP_ITERS`
  if you care about peak performance rather than warmup behaviour.
- The benchmarks here are CPU-bound microbenchmarks from the Computer
  Language Benchmarks Game. They are not representative of Rails workloads.

## Source

Benchmarks adapted from [Shopify/yjit-bench](https://github.com/Shopify/yjit-bench)
(MIT). Methodology follows
[Eregon (2022)](https://eregon.me/blog/2022/01/06/benchmarking-cruby-mjit-yjit-jruby-truffleruby.html).
