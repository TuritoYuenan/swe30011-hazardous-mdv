defmodule HazardousMDV.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("<*> Starting Edge Services...")

    env = environment_variables()

    wait_for_uart_port(env.uart_port)

    children = [
      # First level: Integration with serial port and database
      {Service.Database, env.db_file},
      {Service.SerialConnection, %{port: env.uart_port, rate: env.baud_rate}},

      # Second level: Data collecting and monitoring
      {Service.ETLPipeline, []},
      {Service.Monitoring, []},
    ]

    options = [strategy: :one_for_one, name: HazardousMDV.Supervisor]
    Supervisor.start_link(children, options)
  end

  @impl true
  def stop(_state) do
    Logger.info("<*> Stopping Edge Services...")
    Supervisor.stop(HazardousMDV.Supervisor, :normal, 5000)
    :ok
  end

  # MARK: Private Functions

  defp environment_variables do
    %{
      db_file: Application.fetch_env!(:hazardous_mdv, :db_file),
      uart_port: Application.fetch_env!(:hazardous_mdv, :uart_port),
      baud_rate: Application.fetch_env!(:hazardous_mdv, :baud_rate)
    }
  end

  defp wait_for_uart_port(port) do
    unless port_available?(port) do
      Logger.info("<*> Waiting for UART port #{port} ...")
      :timer.sleep(1000)
      wait_for_uart_port(port)
    end
  end

  defp port_available?(port) do
    Enum.any?(Circuits.UART.enumerate(), fn {name, _info} -> name == port end)
  end
end
