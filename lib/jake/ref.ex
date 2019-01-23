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
        process_local_path(uri) |> get_head_list_path(context.root)
      end

    new_child = Map.drop(spec, ["$ref"]) |> Map.merge(ref_map)

    {%{context | child: new_child}, true}
  end

  def expand_ref(%Context{child: _spec} = context) do
    {context, false}
  end

  def get_head_list_path(path_list, root_schema) do
    {head, tail} = Enum.split(path_list, -1)

    head_path =
      if length(head) > 0 do
        get_in(root_schema, head)
      else
        get_in(root_schema, path_list)
      end

    tail =
      if is_list(head_path) do
        Enum.fetch!(tail, 0)
      else
        nil
      end

    if tail != nil and is_numeric(tail) do
      {index, ""} = Integer.parse(tail)
      Enum.fetch!(head_path, index)
    else
      get_in(root_schema, path_list)
    end
  end

  def process_http_path(url) do
    [url, local] =
      if String.contains?(url, "#/") do
        String.split(url, "#/")
      else
        [url, nil]
      end

    {:ok, {{_, 200, _}, _, schema}} = :httpc.request(:get, {to_charlist(url), []}, [], [])
    jschema = Jason.decode!(schema)

    if is_nil(local) do
      jschema
    else
      process_local_path(local) |> get_head_list_path(jschema)
    end
  end

  def process_local_path(path) do
    str =
      String.replace(path, "~0", "~")
      |> String.replace("#/", "", global: false)

    if String.contains?(str, "~1") do
      strlist = String.split(str, "/")
      for n <- strlist, do: String.replace(n, "~1", "/")
    else
      String.split(str, "/")
    end
  end

  def is_numeric(str) do
    case Integer.parse(str) do
      {_num, ""} -> true
      _ -> false
    end
  end
end
