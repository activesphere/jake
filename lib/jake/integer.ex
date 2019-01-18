defmodule Jake.Integer do
  alias Jake.StreamUtil

  def gen(spec, schema) do
    min = Map.get(spec, "minimum")
    max = Map.get(spec, "maximum")
    exclusive_min = Map.get(spec, "exclusiveMinimum", false)
    exclusive_max = Map.get(spec, "exclusiveMaximum", false)
    StreamUtil.between(:integer, min, max, exclusive_min, exclusive_max)
  end
end
