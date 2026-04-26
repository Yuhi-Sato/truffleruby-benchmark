# The Computer Language Benchmarks Game
# https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
#
# contributed by Jesse Millikan
# Modified by Wesley Moxam
#
# Adapted from Shopify/yjit-bench.

require_relative "harness"

def item_check(left, right)
  return 1 if left.nil?
  1 + item_check(*left) + item_check(*right)
end

def bottom_up_tree(depth)
  return [nil, nil] unless depth > 0
  depth -= 1
  [bottom_up_tree(depth), bottom_up_tree(depth)]
end

MAX_DEPTH = 14
MIN_DEPTH = 4
STRETCH_DEPTH = MAX_DEPTH + 1

run_benchmark do
  stretch_tree = bottom_up_tree(STRETCH_DEPTH)
  stretch_tree = nil

  long_lived_tree = bottom_up_tree(MAX_DEPTH)

  MIN_DEPTH.step(MAX_DEPTH, 2) do |depth|
    iterations = 2**(MAX_DEPTH - depth + MIN_DEPTH)
    check = 0
    1.upto(iterations) do
      temp_tree = bottom_up_tree(depth)
      check += item_check(*temp_tree)
    end
  end

  long_lived_tree
end
