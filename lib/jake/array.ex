defmodule Jake.Array do
  def gen(spec) do
    items = Map.get(spec, "items", %{})
    uniq = Map.get(spec, "uniqueItems", false)
    additional_items = Map.get(spec, "additionalItems", %{})
    max_items = Map.get(spec, "maxItems", 100)
    min_items = Map.get(spec, "minItems", 0)

    case {items, uniq, additional_items} do
      {items, true, _} when items == %{} ->
        StreamData.string(:ascii)
        |> StreamData.uniq_list_of(max_length: max_items, min_length: min_items)

      {items, false, _} when items == %{} ->
        StreamData.string(:ascii)
        |> StreamData.list_of(max_length: max_items, min_length: min_items)

      {items, _uniq, false} when is_list(items) ->
        items |> Enum.map(&Jake.gen(&1)) |> StreamData.fixed_list()

      {items, _uniq, additional_items} when is_list(items) ->
        fixed_items = items |> Enum.map(&Jake.gen(&1)) |> StreamData.fixed_list()

        StreamData.fixed_list([fixed_items, StreamData.list_of(Jake.gen(additional_items))])
        |> StreamData.map(&List.foldl(&1, [], fn x, acc -> acc ++ x end))

      {items, true, _} when is_map(items) ->
        items
        |> Jake.gen()
        |> StreamData.uniq_list_of(max_length: max_items, min_length: min_items)

      {items, false, _} when is_map(items) ->
        items |> Jake.gen() |> StreamData.list_of(max_length: max_items, min_length: min_items)
    end
  end
end
