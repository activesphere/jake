defmodule Jake.Object do
  def gen(%{"properties" => properties, "required" => required}) do
    properties
    |> Map.take(required)
    |> Stream.map(fn {name, spec} ->
      {name, Jake.gen(spec)}
    end)
    |> StreamData.fixed_map()
  end

  def gen(%{"properties" => properties}) do
    properties
    |> Stream.map(fn {name, spec} ->
      {name, Jake.gen(spec)}
    end)
    |> StreamData.fixed_map()
  end

  def gen(_) do
    StreamData.fixed_map(%{})
  end
end
