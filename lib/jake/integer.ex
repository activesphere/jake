defmodule Jake.Integer do
  def gen(spec) do
    min = Map.get(spec, "minimum", -9_007_199_254_740_991)
    max = Map.get(spec, "maximum", 9_007_199_254_740_991)
    multipleOf = Map.get(spec, "multipleOf", 1)

    StreamData.integer(trunc(min / multipleOf)..trunc(max / multipleOf))
    |> StreamData.map(&(&1 * multipleOf))
  end
end
