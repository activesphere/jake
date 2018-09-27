defmodule Jake.Object do
  alias Jake.StreamUtil

  def gen(%{"properties" => properties} = spec) do
    required = Map.get(spec, "required", [])

    optional =
      Map.keys(properties)
      |> Enum.filter(&(!Enum.member?(required, &1)))

    {StreamData.fixed_map(as_map(properties, required)),
     StreamUtil.optional_map(as_map(properties, optional))}
    |> StreamData.map(fn {a, b} -> Map.merge(a, b) end)
  end

  def gen(_) do
    StreamData.fixed_map(%{})
  end

  defp as_map(properties, keys) do
    Map.take(properties, keys)
    |> Enum.map(fn {name, spec} ->
      {name, Jake.gen(spec)}
    end)
    |> Enum.into(%{})
  end
end
