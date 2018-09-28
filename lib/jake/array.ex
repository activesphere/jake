defmodule Jake.Array do
  def gen(spec) do
    items = Map.get(spec, "items", %{})
    uniq = Map.get(spec, "uniqueItems", false)
    max_items = Map.get(spec, "maxItems", 100)
    min_items = Map.get(spec, "minItems", 0)

    case {items, uniq} do
      {x, true} when x == %{} ->
        StreamData.string(:ascii)
        |> StreamData.uniq_list_of(max_length: max_items, min_length: min_items)

      {x, false} when x == %{} ->
        StreamData.string(:ascii)
        |> StreamData.list_of(max_length: max_items, min_length: min_items)

      {x, _} when is_list(x) ->
        x |> Enum.map(&Jake.gen(&1)) |> StreamData.fixed_list()

      {x, true} when is_map(x) ->
        x |> Jake.gen() |> StreamData.uniq_list_of(max_length: max_items, min_length: min_items)

      {x, false} when is_map(x) ->
        x |> Jake.gen() |> StreamData.list_of(max_length: max_items, min_length: min_items)
    end
  end
end
