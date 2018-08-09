defmodule Jake.Object do
  def gen(spec) do
    Enum.map(spec["properties"], fn {name, spec} ->
      {name, Jake.gen(spec)}
    end)
    |> Enum.into(%{})
    |> StreamData.fixed_map()
  end
end
