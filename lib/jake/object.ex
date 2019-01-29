defmodule Jake.Object do
  alias Jake.StreamUtil
  alias Jake.Context
  alias Jake.MapUtil

  def gen(%Context{child: spec} = context) do
    properties = Map.get(spec, "properties", %{})

    if map_size(properties) == 0 and spec["patternProperties"] do
      gen_pattern_properties(context)
    else
      new_child = Map.put(spec, "properties", properties)
      gen_regular_object(%{context | child: new_child})
    end
  end

  defp gen_pattern_properties(
         %Context{child: %{"patternProperties" => patternProperties} = _spec} = context
       ) do
    nlist =
      for {k, v} <- patternProperties,
          do: build_and_verify_patterns(k, v, patternProperties, context)

    merge_patterns(nlist)
  end

  defp gen_regular_object(%Context{child: %{"properties" => properties} = spec} = context) do
    nproperties = check_pattern_properties(spec, properties, spec["patternProperties"])

    properties =
      if is_list(nproperties) and length(nproperties) > 0 do
        Enum.reduce(nproperties, %{}, fn x, acc -> MapUtil.deep_merge(x, acc) end)
      else
        properties
      end
    spec = Map.put(spec, "properties", properties)
    context = %{context | child: spec}
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

  defp check_pattern_properties(_spec, properties, pprop) do
    if pprop do
      pprop_list = Map.to_list(pprop)

      Map.to_list(properties)
      |> Enum.map(fn {k, v} ->
        Enum.map(pprop_list, fn {key, value} ->
          if Regex.match?(~r/#{key}/, k) do
            Map.put(properties, k, Map.merge(v, value))
          end
        end)
      end) |> List.flatten() |> Enum.uniq() |> List.delete(nil)
    else
      properties
    end
  end

  defp merge_patterns(nlist) do
    merge_maps = fn list -> Enum.reduce(list, %{}, fn x, acc -> Map.merge(acc, x) end) end

    StreamData.bind(StreamData.fixed_list(nlist), fn list ->
      StreamData.constant(merge_maps.(list))
    end)
  end

  defp build_and_verify_patterns(key, value, pprop, context) do
    pprop_schema = %{"patternProperties" => pprop}
    # IO.inspect(pprop_schema)
    nkey = Randex.stream(~r/#{key}/, mod: Randex.Generator.StreamData)
    nval = %{context | child: value} |> Jake.gen_lazy()

    StreamData.bind(nkey, fn k ->
      StreamData.bind_filter(
        nval,
        fn v ->
          result = ExJsonSchema.Validator.valid?(pprop_schema, %{k => v})
          if result, do: {:cont, StreamData.constant(%{k => v})}, else: :skip
        end,
        100
      )
    end)
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
