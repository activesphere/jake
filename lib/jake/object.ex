defmodule Jake.Object do
  def gen(%{"properties" => properties, "required" => required}) do
    required_elements =
      properties
      |> Map.take(required)

    properties
    |> Enum.take_random(:rand.uniform(map_size(properties)) - 1)
    |> Map.new()
    |> Map.merge(required_elements)
    |> Enum.map(fn {name, spec} ->
      {name, Jake.gen(spec)}
    end)
    |> Enum.into(%{})
    |> StreamData.fixed_map()
  end

  def gen(%{"properties" => properties}) do
    properties
    |> Enum.take_random(:rand.uniform(map_size(properties)) - 1)
    |> Enum.map(fn {name, spec} ->
      {name, Jake.gen(spec)}
    end)
    |> Enum.into(%{})
    |> StreamData.fixed_map()
  end

  def gen(_) do
    StreamData.fixed_map(%{})
  end
end
