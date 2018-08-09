defmodule Jake.Null do
  def gen(_) do
    StreamData.constant(nil)
  end
end
