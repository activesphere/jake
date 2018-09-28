defmodule Jake.Array do
  def gen(spec) do
    items = Map.get(spec, "items", nil)

    case items do
      x when is_nil(x) -> StreamData.uniq_list_of(StreamData.string(:ascii))
      x when is_list(x) -> x |> Enum.map(&Jake.gen(&1)) |> StreamData.fixed_list()
      x -> x |> Jake.gen() |> StreamData.uniq_list_of()
    end
  end
end
