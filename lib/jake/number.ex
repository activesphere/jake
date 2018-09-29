defmodule Jake.Number do
  def gen(spec) do
    min = Map.get(spec, "minimum", -9_007_199_254_740_991)
    max = Map.get(spec, "maximum", 9_007_199_254_740_991)

    multipleOf = Map.get(spec, "multipleOf", 1)

    case multipleOf do
      multipleOf when multipleOf == 1 ->
        StreamData.float(min: min, max: max)

      multipleOf ->
        StreamData.integer(trunc(min / multipleOf)..trunc(max / multipleOf))
        |> StreamData.map(&(&1 * multipleOf))
        |> StreamData.map(&Float.round(&1 + 0.0, 5))
    end
  end
end
