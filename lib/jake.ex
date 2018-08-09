defmodule Jake do
  def gen(%{"type" => type} = spec) when is_binary(type) do
    module = String.to_existing_atom("Elixir.Jake.#{String.capitalize(type)}")
    apply(module, :gen, [spec])
  end

  def gen(%{"type" => types} = spec) when is_list(types) do
    Enum.map(types, fn type ->
      gen(%{spec | "type" => type})
    end)
    |> StreamData.one_of()
  end
end
