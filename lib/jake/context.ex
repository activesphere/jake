defmodule Jake.Context do
  defstruct root: %{},
            child: %{},
            size: 0,
            root_dir: "/",
            cache: %{}
end
