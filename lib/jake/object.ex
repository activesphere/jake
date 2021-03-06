defmodule Jake.Object do
  alias Jake.StreamUtil
  alias Jake.Context

  def gen(%Context{child: spec} = context) do
    properties = Map.get(spec, "properties", %{})
    required = Map.get(spec, "required", [])
    all_properties = Map.keys(properties)
    optional = Enum.filter(all_properties, &(!Enum.member?(required, &1)))

    additional_properties = Map.get(spec, "additionalProperties", %{})
    max = Map.get(spec, "maxProperties", length(required) + 10)
    min = Map.get(spec, "minProperties", length(required))
    optional_min = Enum.max([min - length(required), 0])
    optional_max = Enum.min([max - length(required), length(optional)])
    additional_min = optional_min - length(optional)
    additional_max = max - length(required) - length(optional)

    additional(additional_properties, all_properties, additional_min..additional_max, context)
    |> StreamUtil.merge(
      StreamUtil.optional_map(
        as_map(properties, optional, context),
        optional_min..optional_max
      )
    )
    |> StreamUtil.merge(StreamData.fixed_map(as_map(properties, required, context)))
  end

  defp additional(properties, _all, min.._max, _context) when min < 0 or not is_map(properties) do
    StreamData.constant(%{})
  end

  defp additional(properties, all, min..max, context) do
    Randex.stream(~r/[a-zA-Z_]\w{0,5}/, mod: Randex.Generator.StreamData)
    |> StreamData.filter(fn x -> !Enum.member?(all, x) end)
    |> StreamData.uniq_list_of(min_length: min, max_length: max)
    |> StreamData.bind(fn keys ->
      Enum.map(keys, fn key ->
        {key, Jake.gen_lazy(%{context | child: properties})}
      end)
      |> Enum.into(%{})
      |> StreamData.fixed_map()
    end)
    |> StreamData.scale(fn size -> trunc(size / 10) end)
  end

  defp as_map(properties, keys, context) do
    Map.take(properties, keys)
    |> Enum.map(fn {name, spec} ->
      {name, Jake.gen_lazy(%{context | child: spec})}
    end)
    |> Enum.into(%{})
  end
end
