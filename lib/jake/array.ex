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
        fixed_items_generator = items |> Enum.map(&Jake.gen(&1)) |> StreamData.fixed_list()

        additional_items_generator =
          StreamData.integer(min_items..max_items)
          |> StreamData.bind(fn n ->
            additional_length =
              if(n < length(items)) do
                0
              else
                n - length(items)
              end

            StreamData.list_of(Jake.gen(additional_items), length: additional_length)
          end)

        StreamData.fixed_list([fixed_items_generator, additional_items_generator])
        |> StreamData.map(&Enum.concat/1)

      {items, true, _} when is_map(items) ->
        Jake.gen(items)
        |> StreamData.uniq_list_of(max_length: max_items, min_length: min_items)

      {items, false, _} when is_map(items) ->
        Jake.gen(items)
        |> StreamData.list_of(max_length: max_items, min_length: min_items)
    end
  end
end
