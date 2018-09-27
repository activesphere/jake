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
end
