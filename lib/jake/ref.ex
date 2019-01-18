defmodule Jake.Ref do
  def expand_ref(ref, map, _omap)
      when is_nil(ref) or is_map(ref) do
    {map, false}
  end
end
