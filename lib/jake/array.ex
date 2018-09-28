defmodule Jake.Array do
  def gen(spec) do
    items = Map.get(spec, "items", nil)
    max_items = Map.get(spec, "maxItems", 100)
    min_items = Map.get(spec, "minItems", 0)

    case items do
      nil -> StreamData.uniq_list_of(StreamData.string(:ascii), max_length: max_items, min_length: min_items)
      x when is_list(x) -> x |> Enum.map(&Jake.gen(&1)) |> StreamData.fixed_list()
      x -> x |> Jake.gen() |> StreamData.uniq_list_of(max_length: max_items, min_length: min_items)
    end
  end
end
