defmodule Jake.Array do
  def gen(spec, context) do
    items = Map.get(spec, "items", %{})
    uniq = Map.get(spec, "uniqueItems", false)
    additional_items = Map.get(spec, "additionalItems", %{})
    max_items = Map.get(spec, "maxItems", 10)
    min_items = Map.get(spec, "minItems", 0)

    list_of = if uniq, do: &StreamData.uniq_list_of/2, else: &StreamData.list_of/2

    if is_list(items) do
      additional_items =
        if is_map(additional_items) do
          Stream.cycle([additional_items])
        else
          []
        end

      items = Stream.concat([items, additional_items])

      StreamData.bind(StreamData.integer(min_items..max_items), fn count ->
        list = Enum.take(items, count)

        for(n <- list, do: %{context | child: n})
        |> Enum.map(&Jake.gen_lazy(&1))
        |> StreamData.fixed_list()
      end)
      |> StreamData.filter(fn x ->
        !uniq || length(Enum.uniq(x)) == length(x)
      end)
    else
      %{context | child: items}
      |> Jake.gen_lazy()
      |> list_of.(min_length: min_items, max_length: max_items)
    end
  end
end
