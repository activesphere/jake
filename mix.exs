defmodule Jake.MixProject do
  use Mix.Project

  def project do
    [
      app: :jake,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:stream_data, "~> 0.4"},
      {:ex_json_schema, "~> 0.5"}
    ]
  end
end
