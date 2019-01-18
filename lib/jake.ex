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

        cond do
          nmap["allOf"] || nmap["oneOf"] || nmap["anyOf"] || nmap["not"] ->
            Jake.Mixed.gen_mixed(nmap, nschema)

          nmap["enum"] ->
            gen_enum(nschema, nmap["enum"])

          true ->
            gen_type(nschema)
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

  def gen_type(schema) do
    schema["map"] |> gen(schema)
  end

  def gen(%{"type" => type} = spec, schema) when is_binary(type) do
    module = String.to_existing_atom("Elixir.Jake.#{String.capitalize(type)}")
    apply(module, :gen, [spec, schema])
  end

  def gen(%{"type" => types} = spec, schema) when is_list(types) do
    list = for n <- types, do: %{"type" => n}
    nmap = Map.drop(spec, ["type"])

    for(n <- list, is_map(n), do: Map.put(schema, "map", Map.merge(n, nmap)) |> Jake.gen_init())
    |> StreamData.one_of()
  end

  # type not present
  def gen(spec, schema) do
    Jake.Notype.gen_notype(nil, schema)
  end
end
