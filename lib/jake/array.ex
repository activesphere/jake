defmodule Jake.Array do
  def gen(spec) do
    items = Map.get(spec, "items", %{})
    uniq = Map.get(spec, "uniqueItems", false)
    additional_items = Map.get(spec, "additionalItems", %{})
    max_items = Map.get(spec, "maxItems", 10)
    min_items = Map.get(spec, "minItems", 0)

    case {items, uniq, additional_items} do
      {items, true, _} when items == %{} ->
        StreamData.string(:ascii)
        |> StreamData.uniq_list_of(max_length: max_items, min_length: min_items)

      {items, false, _} when items == %{} ->
        StreamData.string(:ascii)
        |> StreamData.list_of(max_length: max_items, min_length: min_items)

      {items, true, false} when is_list(items) ->
        items
        |> Enum.map(&Jake.gen(&1))
        |> StreamData.fixed_list()
        |> StreamData.map(&Enum.uniq/1)
        |> StreamData.filter(&(length(&1) == length(items)))

      {items, false, false} when is_list(items) ->
        items
        |> Enum.map(&Jake.gen(&1))
        |> StreamData.fixed_list()

      {items, true, additional_items} when is_list(items) ->
        fixed_items_generator =
          items
          |> Enum.map(&Jake.gen(&1))
          |> StreamData.fixed_list()
          |> StreamData.map(&Enum.uniq/1)
          |> StreamData.filter(&(length(&1) == length(items)))

        min_bound = min_items - length(items)
        max_bound = max_items - length(items)

        min_bound = if min_bound < 0, do: 0, else: min_bound

        max_bound = if max_bound < 0, do: 0, else: max_bound

        additional_items_generator =
          StreamData.uniq_list_of(
            Jake.gen(additional_items),
            min_length: min_bound,
            max_length: max_bound
          )

        StreamData.fixed_list([fixed_items_generator, additional_items_generator])
        |> StreamData.map(&Enum.concat/1)
        |> StreamData.map(&Enum.uniq/1)

      {items, false, additional_items} when is_list(items) ->
        fixed_items_generator =
          items
          |> Enum.map(&Jake.gen(&1))
          |> StreamData.fixed_list()

        min_bound = min_items - length(items)
        max_bound = max_items - length(items)

        min_bound = if min_bound < 0, do: 0, else: min_bound

        max_bound = if max_bound < 0, do: 0, else: max_bound

        additional_items_generator =
          StreamData.list_of(
            Jake.gen(additional_items),
            min_length: min_bound,
            max_length: max_bound
          )

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
