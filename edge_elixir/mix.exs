defmodule HazardousMDV.MixProject do
  use Mix.Project

  def project do
    [
      app: :hazardous_mdv,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {HazardousMDV.Application, []},
      env: [
        db_file: "sensor_data.db",
        uart_port: "COM8",
        baud_rate: 9600
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Main edge server
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:circuits_uart, "~> 1.5"},
      {:exqlite, "~> 0.27"}
    ]
  end
end
