defmodule Jake.Null do
  def gen(_, _) do
    StreamData.constant(nil)
  end
end
