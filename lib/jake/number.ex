defmodule Jake.Number do
  def gen(spec) do
    min = Map.get(spec, "minimum", -9_007_199_254_740_991)
    max = Map.get(spec, "maximum", 9_007_199_254_740_991)
    StreamData.float(min: min, max: max)
  end
end
