defmodule Jake.Number do
  def gen(spec) do
    min = Map.get(spec, "minimum", -9_007_199_254_740_991)
    max = Map.get(spec, "maximum", 9_007_199_254_740_991)
    exclusive_min = Map.get(spec, "exclusiveMinimum", false)
    exclusive_max = Map.get(spec, "exclusiveMaximum", false)

    multipleOf = Map.get(spec, "multipleOf", 1)

    case {multipleOf, exclusive_min, exclusive_max} do
      {multipleOf, false, false} when multipleOf == 1 ->
        StreamData.float(min: min, max: max)

      {multipleOf, _exclusive_min, false} when multipleOf == 1 ->
        StreamData.float(min: min, max: max)
        |> StreamData.filter(&(&1 != min))

      {multipleOf, false, _exclusive_max} when multipleOf == 1 ->
        StreamData.float(min: min, max: max)
        |> StreamData.filter(&(&1 != max))

      {multipleOf, _, _} when multipleOf == 1 ->
        StreamData.float(min: min, max: max)
        |> StreamData.filter(&(&1 != min))
        |> StreamData.filter(&(&1 != max))

      {multipleOf, false, false} ->
        StreamData.integer(trunc(min / multipleOf)..trunc(max / multipleOf))
        |> StreamData.map(&(&1 * multipleOf))
        |> StreamData.map(&Float.round(&1 + 0.0, 5))

      {multipleOf, exclusive_min, exclusive_max} ->
        min_bound =
          if exclusive_min == false,
            do: trunc(min / multipleOf),
            else: trunc(min / multipleOf) + 1

        max_bound =
          if exclusive_max == false,
            do: trunc(max / multipleOf),
            else: trunc(max / multipleOf) - 1

        StreamData.integer(min_bound..max_bound)
        |> StreamData.map(&(&1 * multipleOf))
        |> StreamData.map(&Float.round(&1 + 0.0, 5))
    end
  end
end
