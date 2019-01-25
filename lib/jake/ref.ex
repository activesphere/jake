defmodule Jake.Ref do
  alias Jake.Context

  def expand_ref(%Context{child: %{"$ref" => ref} = spec} = context)
      when ref == "#" do
    new_child = Map.drop(spec, ["$ref"]) |> Map.merge(context.root)
    {%{context | child: new_child}, true}
  end

  def expand_ref(%Context{child: %{"$ref" => ref} = spec} = context) when is_binary(ref) do
    uri = URI.decode(ref)

    ref_map =
      if String.starts_with?(uri, "http") do
        process_http_path(uri)
      else
        {:ok, value} = JSONPointer.get(context.root, uri)
        value
      end

    new_child = Map.drop(spec, ["$ref"]) |> Map.merge(ref_map)

    {%{context | child: new_child}, true}
  end

  def expand_ref(%Context{child: _spec} = context) do
    {context, false}
  end

  def process_http_path(url) do
    [url, local] =
      if String.contains?(url, "#") do
        u = URI.parse(url)
        ["#{u.scheme}//#{u.authority}:#{u.port}#{u.path}", u.fragment]
      else
        [url, nil]
      end

    {:ok, {{_, 200, _}, _, schema}} = :httpc.request(:get, {to_charlist(url), []}, [], [])
    jschema = Jason.decode!(schema)

    if is_nil(local) do
      jschema
    else
      {:ok, value} = JSONPointer.get(jschema, local)
      value
    end
  end
end
