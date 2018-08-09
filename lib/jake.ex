defmodule Jake do
  def gen(%{"type" => "object"} = spec) do
    Jake.Object.gen(spec)
  end

  def gen(%{"type" => "string"} = spec) do
    Jake.String.gen(spec)
  end
end
