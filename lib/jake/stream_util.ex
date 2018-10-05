defmodule Jake.StreamUtil do
  def some_of(datas) do
    StreamData.integer(0..length(datas))
    |> StreamData.bind(fn n ->
      StreamData.fixed_list(Enum.take(datas, n))
    end)
  end

  def optional_map(map) do
    Map.to_list(map)
    |> Enum.map(fn {key, value} ->
      {StreamData.constant(key), value}
    end)
    |> some_of()
    |> StreamData.map(&Enum.into(&1, %{}))
  end

  def between(type, min, max, exclusive_min, exclusive_max) do
    case type do
      :integer ->
        StreamData.integer(
          ceil(min || -9_007_199_254_740_991)..trunc(max || 9_007_199_254_740_991)
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

  defp ceil(x) do
    trunc(Float.ceil(x * 1.0))
  end
end
