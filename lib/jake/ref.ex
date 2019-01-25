defmodule Jake.Ref do
  alias Jake.Context

  def expand_ref(%Context{child: %{"$ref" => ref} = spec} = context)
      when ref == "#" do
    new_child = Map.drop(spec, ["$ref"]) |> Map.merge(context.root)
    {%{context | child: new_child}, true}
  end

  def expand_ref(%Context{child: %{"$ref" => ref} = spec} = context) when is_binary(ref) do
    uri_parse = URI.decode(ref) |> URI.parse()

    {context, ref_map} =
      cond do
        uri_parse.scheme in ["http", "https"] ->
          process_http_path(uri_parse, context)

        uri_parse.path == nil and is_binary(uri_parse.fragment) ->
          {context, JSONPointer.get!(context.root, uri_parse.fragment)}

        is_binary(uri_parse.path) and is_binary(uri_parse.fragment) ->
          ref_map =
            Path.join(context.default_path, uri_parse.path)
            |> File.read!()
            |> Jason.decode!()
            |> JSONPointer.get!(uri_parse.fragment)

          {context, ref_map}
      end

    new_child = Map.drop(spec, ["$ref"]) |> Map.merge(ref_map)

    {%{context | child: new_child}, true}
  end

  def expand_ref(%Context{child: _spec} = context) do
    {context, false}
  end

  def process_http_path(uri_parse, context) do
    url = "#{uri_parse.scheme}://#{uri_parse.authority}:#{uri_parse.port}#{uri_parse.path}"

    {context, schema} =
      if context.cache[url] == nil do
        {:ok, {{_, 200, _}, _, schema}} = :httpc.request(:get, {to_charlist(url), []}, [], [])
        new_cache = Map.put(context.cache, url, schema)
        {%{context | cache: new_cache}, schema}
      else
        {context, context.cache[url]}
      end

    jschema = Jason.decode!(schema)

    if uri_parse.fragment do
      {context, JSONPointer.get!(jschema, uri_parse.fragment)}
    else
      {context, jschema}
    end
  end
end
