defmodule Jake.Object do
  def gen(%{"properties" => properties}) do
    Enum.map(properties, fn {name, spec} ->
      {name, Jake.gen(spec)}
    end)
    |> Enum.into(%{})
    |> StreamData.fixed_map()
  end

  def gen(_) do
    StreamData.fixed_map(%{})
  end
end
