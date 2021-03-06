defmodule Jake.String do
  alias Jake.Context

  def gen(%Context{child: spec} = _context) do
    options = []
    min_length = Map.get(spec, "minLength")
    max_length = Map.get(spec, "maxLength")

    options =
      if min_length do
        Keyword.put(options, :min_length, min_length)
      else
        options
      end

    options =
      if max_length do
        Keyword.put(options, :max_length, max_length)
      else
        options
      end

    pattern = Map.get(spec, "pattern")

    if pattern do
      Randex.stream(pattern, mod: Randex.Generator.StreamData)
      |> StreamData.filter(fn x ->
        (!max_length || String.length(x) <= max_length) &&
          (!min_length || String.length(x) >= min_length)
      end)
    else
      StreamData.string(:ascii, options)
    end
  end
end
