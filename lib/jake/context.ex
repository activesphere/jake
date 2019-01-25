defmodule Jake.Context do
  defstruct root: %{},
            child: %{},
            size: 0,
            default_path: File.cwd!(),
            cache: %{}
end
