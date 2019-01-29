defmodule Jake.Ref do
  alias Jake.Context

  def expand_ref(%Context{child: %{"$ref" => ref} = spec} = context)
      when ref == "#" do
    new_child = Map.drop(spec, ["$ref"]) |> Map.merge(context.root)
    {%{context | child: new_child}, true}
  end

  def expand_ref(%Context{child: %{"$ref" => ref} = spec} = context) when is_binary(ref) do
    parsed_uri = URI.decode(ref) |> URI.parse()

    {context, ref_map} =
      cond do
        parsed_uri.scheme in ["http", "https"] ->
          process_http_path(parsed_uri, context)

        parsed_uri.path == nil and is_binary(parsed_uri.fragment) ->
          {context, JSONPointer.get!(context.root, parsed_uri.fragment)}

        is_binary(parsed_uri.path) and is_binary(parsed_uri.fragment) ->
          ref_map =
            File.cwd!()
            |> Path.join(parsed_uri.path)
            |> File.read!()
            |> Jason.decode!()
            |> JSONPointer.get!(parsed_uri.fragment)

          {context, ref_map}
      end

    new_child = Map.drop(spec, ["$ref"]) |> Map.merge(ref_map)

    {%{context | child: new_child}, true}
  end

  def expand_ref(%Context{child: _spec} = context) do
    {context, false}
  end

  def process_http_path(parsed_uri, context) do
    url = "#{parsed_uri.scheme}://#{parsed_uri.authority}:#{parsed_uri.port}#{parsed_uri.path}"

    {context, schema} =
      if context.cache[url] == nil do
        {:ok, {{_, 200, _}, _, schema}} = :httpc.request(:get, {to_charlist(url), []}, [], [])
        new_cache = Map.put(context.cache, url, schema)
        {%{context | cache: new_cache}, schema}
      else
        {context, context.cache[url]}
      end

    jschema = Jason.decode!(schema)

    if parsed_uri.fragment do
      {context, JSONPointer.get!(jschema, parsed_uri.fragment)}
    else
      {context, jschema}
    end
  end
end
