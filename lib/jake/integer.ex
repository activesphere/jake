defmodule Jake.Integer do
  def gen(spec) do
    min = Map.get(spec, "minimum")
    max = Map.get(spec, "maximum")
    exclusive_min = Map.get(spec, "exclusiveMinimum", false)
    exclusive_max = Map.get(spec, "exclusiveMaximum", false)
    multipleOf = Map.get(spec, "multipleOf", 1)

    min_bound =
      case {min, exclusive_min} do
        {nil, false} -> -9_007_199_254_740_991
        {min, true} -> min + 1
        {min, false} -> min
      end

    max_bound =
      case {max, exclusive_max} do
        {nil, false} -> 9_007_199_254_740_991
        {max, true} -> max - 1
        {max, false} -> max
      end

    StreamData.integer(trunc(min_bound / multipleOf)..trunc(max_bound / multipleOf))
    |> StreamData.map(&(&1 * multipleOf))
  end
end
