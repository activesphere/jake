defmodule Jake.String do
  def gen(spec) do
    options = []

    options =
      if min_length = Map.get(spec, "minLength") do
        Keyword.put(options, :min_length, min_length)
      else
        options
      end

    options =
      if max_length = Map.get(spec, "maxLength") do
        Keyword.put(options, :max_length, max_length)
      else
        options
      end

    StreamData.string(:ascii, options)
  end
end
