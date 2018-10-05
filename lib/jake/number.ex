defmodule Jake.Number do
  alias Jake.StreamUtil

  def gen(spec) do
    min = Map.get(spec, "minimum")
    max = Map.get(spec, "maximum")
    exclusive_min = Map.get(spec, "exclusiveMinimum", false)
    exclusive_max = Map.get(spec, "exclusiveMaximum", false)

    StreamData.one_of([
      StreamUtil.between(:float, min, max, exclusive_min, exclusive_max),
      StreamUtil.between(:integer, min, max, exclusive_min, exclusive_max)
    ])
  end
end
