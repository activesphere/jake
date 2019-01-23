defmodule Jake.Ref do
  alias Jake.Context

  def expand_ref(%Context{child: _spec} = context) do
    {context, false}
  end
end
