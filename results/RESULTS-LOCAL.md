# Benchmark Results — local rbenv run

Re-run of the same harness against engines installed via `rbenv` (no Docker).
This corrects the bias introduced by the Docker run, which had to fall back
to a 4-year-old TruffleRuby 21.2 image because `ghcr.io/graalvm/truffleruby`
was unreachable.

Run on 2026-04-26. Iterations: 15 warmup + 20 measured per (engine, benchmark).
Best-of-20 reported.

## Engines

| Tag         | Install                              | RUBY_DESCRIPTION                                                            |
|-------------|--------------------------------------|-----------------------------------------------------------------------------|
| yjit        | `rbenv install 4.0.2`, `--yjit`      | ruby 4.0.2 (2026-04-26) +YJIT +PRISM [x86_64-linux]                         |
| zjit        | `rbenv install 4.0.2`, `--zjit`      | ruby 4.0.2 (2026-04-26) +ZJIT +PRISM [x86_64-linux]                         |
| truffleruby | `rbenv install truffleruby-33.0.1`   | truffleruby 33.0.1 (2026-01-20), like ruby 3.3.7, Oracle GraalVM Native     |

## Best time per iteration (seconds, lower is better)

| Benchmark      |    YJIT |    ZJIT | TruffleRuby |
|----------------|--------:|--------:|------------:|
| binarytrees    |  0.1423 |  0.2773 |      0.0737 |
| fannkuchredux  |  0.1131 |  0.1866 |      0.0206 |
| nbody          |  0.0282 |  0.0559 |      0.0022 |

## Speedup relative to YJIT (higher = faster)

| Benchmark      |  YJIT |  ZJIT | TruffleRuby |
|----------------|------:|------:|------------:|
| binarytrees    | 1.00× | 0.51× |      1.93×  |
| fannkuchredux  | 1.00× | 0.61× |      5.50×  |
| nbody          | 1.00× | 0.50× |     12.64×  |

## Comparison vs. Docker run

| Benchmark      | TruffleRuby (Docker, 21.2) | TruffleRuby (local, 33.0.1) | Improvement |
|----------------|---------------------------:|----------------------------:|------------:|
| binarytrees    |                     0.46×  |                       1.93× |       4.2×  |
| fannkuchredux  |                     4.34×  |                       5.50× |       1.3×  |
| nbody          |                     3.51×  |                      12.64× |       3.6×  |

The 4-year version gap on TruffleRuby was costing 1.3×–4.2× relative to YJIT.
Most strikingly, `binarytrees` flipped from a TruffleRuby loss (0.46×) to a
near-2× win (1.93×) — TruffleRuby's young-generation GC and allocation
inlining have improved dramatically since 21.2.

## Observations

- **TruffleRuby > YJIT > ZJIT** on every benchmark. ZJIT is opt-in /
  experimental in 4.0; the upstream goal is for it to surpass YJIT in 4.1.
- **TruffleRuby trounces numerical workloads** — `nbody` 12.64×, `fannkuchredux`
  5.50× vs YJIT. Partial evaluation + escape analysis on `Float` arithmetic
  pays off massively, in line with Eregon's 2022 results.
- **TruffleRuby now wins `binarytrees` too** (1.93×), unlike both Eregon's
  2022 number (2.73× vs CRuby 3.1) and our Docker run (0.46× vs YJIT 4.0.2).
  CRuby+YJIT got faster, but TruffleRuby's allocation/GC stack got faster
  faster.
- **Warmup matters but converges fast at this scale.** The TruffleRuby
  `nbody` warmup tail dropped from 0.061s on iteration 1 to 0.0023s by
  iteration 6. With 15 warmup runs the measurement window is comfortably
  steady-state.
- **ZJIT is consistently ~half the speed of YJIT** here. Expected for an
  experimental method-JIT in its first shipping release.

## Raw output

Per-engine, per-benchmark `RESULT { ... }` JSON lines under
`results/local-<engine>-<benchmark>.log`.
