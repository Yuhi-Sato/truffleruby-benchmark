# Benchmark Results

Run on 2026-04-26 inside the project's Docker images.
Iterations: 3 warmup + 5 measured per (engine, benchmark). Best-of-5 reported.

## Engines

| Tag         | Image                                | RUBY_DESCRIPTION                                                |
|-------------|--------------------------------------|-----------------------------------------------------------------|
| yjit        | ruby:4.0.2-slim, `--yjit`            | ruby 4.0.2 (2026-03-17 revision d3da9fec82) +YJIT +PRISM        |
| zjit        | ruby:4.0.2-slim, `--zjit`            | ruby 4.0.2 (2026-03-17 revision d3da9fec82) +ZJIT +PRISM        |
| truffleruby | flavorjones/truffleruby:latest       | truffleruby 21.2.0.1, like ruby 2.7.3, GraalVM CE Native        |

> ⚠️ TruffleRuby is older here (21.2.0.1 / Ruby 2.7.3) because the official
> `ghcr.io/graalvm/truffleruby` registry was returning HTTP 503 from this
> environment. Pin to the official image (`--build-arg TRUFFLERUBY_IMAGE=...`)
> when you have ghcr.io access for an apples-to-apples 4.0-era comparison.

## Best time per iteration (seconds, lower is better)

| Benchmark      |    YJIT |    ZJIT | TruffleRuby |
|----------------|--------:|--------:|------------:|
| binarytrees    |  0.1409 |  0.2732 |      0.3055 |
| fannkuchredux  |  0.1303 |  0.1922 |      0.0300 |
| nbody          |  0.0290 |  0.0590 |      0.0083 |

## Speedup relative to YJIT (higher = faster than YJIT)

| Benchmark      |  YJIT |  ZJIT | TruffleRuby |
|----------------|------:|------:|------------:|
| binarytrees    | 1.00× | 0.52× |       0.46× |
| fannkuchredux  | 1.00× | 0.68× |       4.34× |
| nbody          | 1.00× | 0.49× |       3.51× |

## Observations

- **YJIT > ZJIT on every benchmark.** Expected: ZJIT is opt-in / experimental
  in 4.0; the upstream goal is for it to surpass YJIT in 4.1.
- **TruffleRuby dominates the numerical workloads** (`nbody` ~3.5×,
  `fannkuchredux` ~4.3× vs YJIT) — partial-evaluation + escape analysis on
  `Float` arithmetic pays off massively.
- **TruffleRuby loses on `binarytrees`** — it's an allocation/GC-heavy tree
  workload, and a tight allocation loop is exactly where TruffleRuby's
  strengths matter least and YJIT's lean inline-cached path wins.
- **Warmup matters.** TruffleRuby's `nbody` first measured iteration was
  0.076s, falling to 0.008s by iteration 5; with only 3 warmup runs the
  early measurements still include warmup tail. Bumping `WARMUP_ITERS`
  would push best-of-N closer to peak.

## Raw output

Per-engine, per-benchmark `RESULT { ... }` JSON lines live in
`results/<engine>-<benchmark>.log`.
