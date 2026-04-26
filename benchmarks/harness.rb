# Shared benchmark harness.
#
# Each benchmark file requires this harness and calls `run_benchmark` with a
# block. The harness performs warmup iterations followed by measured iterations
# and prints results as a single RESULT line that the driver can parse.
#
# Inspired by Shopify/yjit-bench but standalone so it works on CRuby (YJIT,
# ZJIT) and TruffleRuby without any external dependency.

require "json"

WARMUP_ITERS  = Integer(ENV.fetch("WARMUP_ITERS",  "5"))
MEASURE_ITERS = Integer(ENV.fetch("MEASURE_ITERS", "10"))

def run_benchmark(_default_iters = nil, &block)
  name = ENV.fetch("BENCH_NAME", File.basename($PROGRAM_NAME, ".rb"))
  engine = "#{RUBY_ENGINE} #{RUBY_VERSION}"

  collect = ->(label, count) {
    times = []
    count.times do |i|
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      block.call
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
      times << elapsed
      STDERR.puts format("[%s] %s %d/%d: %.4fs", name, label, i + 1, count, elapsed)
    end
    times
  }

  warmup_times  = collect.("warmup",  WARMUP_ITERS)
  measure_times = collect.("measure", MEASURE_ITERS)

  best   = measure_times.min
  worst  = measure_times.max
  mean   = measure_times.sum / measure_times.size
  stddev = Math.sqrt(measure_times.sum { |t| (t - mean)**2 } / measure_times.size)

  puts "RESULT #{JSON.generate(
    benchmark: name,
    engine: engine,
    warmup: warmup_times,
    measure: measure_times,
    best: best,
    worst: worst,
    mean: mean,
    stddev: stddev,
  )}"
end
