defmodule Jake.MapUtil do
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, left, nil) do
    left
  end

  defp deep_resolve(_key, nil, right) do
    right
  end

  defp deep_resolve(_key, left, right) when is_map(left) do
    Map.merge(left, right)
  end

  defp deep_resolve(_key, left, right) when is_list(left) do
    left ++ right
  end
end
