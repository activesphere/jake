defmodule Jake.Integer do
  def gen(spec) do
    min = Map.get(spec, "minimum")
    max = Map.get(spec, "maximum")
    exclusive_min = Map.get(spec, "exclusiveMinimum")
    exclusive_max = Map.get(spec, "exclusiveMaximum")
    multipleOf = Map.get(spec, "multipleOf", 1)

    min_bound =
      case {min, exclusive_min} do
        {nil, nil} -> -9_007_199_254_740_991
        {min, nil} -> min
        {nil, exclusive_min} -> exclusive_min + 1
      end

    max_bound =
      case {max, exclusive_max} do
        {nil, nil} -> 9_007_199_254_740_991
        {max, nil} -> max
        {nil, exclusive_max} -> exclusive_max + 1
      end

    StreamData.integer(trunc(min_bound / multipleOf)..trunc(max_bound / multipleOf))
    |> StreamData.map(&(&1 * multipleOf))
  end
end
