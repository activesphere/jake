defmodule Jake.StreamUtil do
  def some_of(datas, range) do
    StreamData.integer(range)
    |> StreamData.bind(fn n ->
      StreamData.fixed_list(Enum.take(datas, n))
    end)
  end

  def optional_map(map, range) do
    Map.to_list(map)
    |> Enum.map(fn {key, value} ->
      {StreamData.constant(key), value}
    end)
    |> some_of(range)
    |> StreamData.map(&Enum.into(&1, %{}))
  end

  def merge(a, b) do
    StreamData.map({a, b}, fn {a, b} -> Map.merge(a, b) end)
  end

  def between(type, min, max, exclusive_min, exclusive_max) do
    case type do
      :integer ->
        StreamData.integer(
          float_ceil(min || -9_007_199_254_740_991)..trunc(max || 9_007_199_254_740_991)
        )

      :float ->
        StreamData.float(min: min, max: max)
    end
    |> StreamData.filter(fn x ->
      less = if exclusive_min, do: &Kernel.<=/2, else: &Kernel.</2
      more = if exclusive_max, do: &Kernel.>=/2, else: &Kernel.>/2
      !((min && less.(x, min)) || (max && more.(x, max)))
    end)
  end

  defp float_ceil(x) do
    trunc(Float.ceil(x * 1.0))
  end
end
