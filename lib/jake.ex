defmodule Jake do
  alias Jake.MapUtil

  @types [
    "array",
    "boolean",
    "integer",
    "null",
    "number",
    "object",
    "string"
  ]

  def generator(map) do
    StreamData.sized(fn size ->
      Map.put(%{}, "map", map) |> Map.put("omap", map) |> Map.put("size", size) |> gen_init()
    end)
  end

  def gen_init(schema) do
    StreamData.bind(
      get_lazy_streamkey(schema),
      fn {nmap, nsize} ->
        nschema = Map.put(schema, "map", nmap) |> Map.put("size", nsize)

        if nmap["enum"] do
          gen_enum(nschema, nmap["enum"])
        else
          gen(nmap, nschema)
        end
        |> StreamData.resize(nsize)
      end
    )
  end

  def get_lazy_streamkey(schema) do
    {map, ref} =
      get_in(schema, ["map", "$ref"]) |> Jake.Ref.expand_ref(schema["map"], schema["omap"])

    if ref do
      StreamData.constant({map, trunc(schema["size"] / 2)})
    else
      StreamData.constant({map, schema["size"]})
    end
  end

  def gen_enum(schema, enum) when is_list(enum) do
    map = schema["map"]

    StreamData.member_of(enum)
    |> StreamData.filter(fn x -> ExJsonSchema.Validator.valid?(map, x) end)
  end

  def gen(%{"anyOf" => options} = spec, schema) when is_list(options) do
    Enum.map(options, fn option ->
      map = Map.merge(Map.drop(spec, ["anyOf"]), option)
      Map.put(schema, "map", map) |> gen_init()
    end)
    |> StreamData.one_of()
  end

  def gen(%{"allOf" => options} = spec, schema) when is_list(options) do
    properties =
      options
      |> Enum.reduce(%{}, fn x, acc -> MapUtil.deep_merge(x, acc) end)

    map =
      spec
      |> Map.drop(["allOf"])
      |> MapUtil.deep_merge(properties)

    Map.put(schema, "map", map) |> gen_init()
  end

  def gen(%{"type" => type} = spec, schema) when is_binary(type) do
    module = String.to_existing_atom("Elixir.Jake.#{String.capitalize(type)}")
    apply(module, :gen, [spec, schema])
  end

  def gen(%{"type" => types} = spec, schema) when is_list(types) do
    Enum.map(types, fn type ->
      map = %{spec | "type" => type}

      Map.put(schema, "map", map)
      |> gen_init()
    end)
    |> StreamData.one_of()
  end

  # type not present
  def gen(spec, schema) do
    StreamData.member_of(@types)
    |> StreamData.bind(fn type ->
      map = Map.put(spec, "type", type)
      size = trunc(schema["size"] / 2)
      Map.put(schema, "map", map) |> Map.put("size", size) |> gen_init()
    end)
  end
end
