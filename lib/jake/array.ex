defmodule Jake.Array do
  def gen(spec, schema) do
    items = Map.get(spec, "items", %{})
    uniq = Map.get(spec, "uniqueItems", false)
    additional_items = Map.get(spec, "additionalItems")
    max_items = Map.get(spec, "maxItems", 10)
    min_items = Map.get(spec, "minItems", 0)

    list_of = if uniq, do: &StreamData.uniq_list_of/2, else: &StreamData.list_of/2

    if is_list(items) do
      additional_items =
        if is_map(additional_items) do
          Stream.cycle([additional_items])
        else
          additional_items
        end

      items =
        cond do
          (is_boolean(additional_items) and additional_items) or is_nil(additional_items) ->
            Stream.cycle(items)

          is_boolean(additional_items) and not additional_items ->
            Stream.concat(items)

          true ->
            Stream.concat([items, additional_items])
        end

      StreamData.bind(StreamData.integer(min_items..max_items), fn count ->
        list = Enum.take(items, count)
        nlist = for n <- list, do: Map.put(schema, "map", n)

        Enum.map(nlist, &Jake.gen_init(&1))
        |> StreamData.fixed_list()
      end)
      |> StreamData.filter(fn x ->
        !uniq || length(Enum.uniq(x)) == length(x)
      end)
    else
      Map.put(schema, "map", items)
      |> Jake.gen_init()
      |> list_of.(min_length: min_items, max_length: max_items)
    end
  end
end
