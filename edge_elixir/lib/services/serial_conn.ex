defmodule Service.SerialConnection do
  use GenServer
  require Logger
  alias Circuits.UART

  # MARK: Client API

  @doc """
  Starts the SerialConnection GenServer with the given serial port and baud rate.
  """
  @doc args: "Serial port and baud rate for UART communication."
  @spec start_link(%{port: String.t(), rate: non_neg_integer()}) :: GenServer.on_start()
  def start_link(opts) do
    Logger.info("> GEN: Starting SerialConnection server | Port: #{opts.port}, Baud Rate: #{opts.rate}")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Stops the SerialConnection GenServer.
  """
  @doc reason: "Reason for stopping the GenServer."
  @spec stop(term()) :: :ok | {:error, term()}
  def stop(reason) do
    Logger.info("> GEN: Stopping SerialConnection server | Reason: #{inspect(reason)}")
    GenServer.stop(__MODULE__, reason)
  end

  @doc """
  Writes data to the serial port.
  """
  @doc data: "Data to write to the serial port."
  @spec write(String.t()) :: :ok
  def write(data) do
    GenServer.call(__MODULE__, {:write, data})
  end

  # MARK: Server Callbacks

  @impl true
  def init(%{port: port, rate: baud}) do
    {:ok, uart_pid} = UART.start_link()
    :ok = UART.open(uart_pid, port, speed: baud, active: true, framing: {UART.Framing.Line, separator: "\r\n"})
    {:ok, %{uart: uart_pid}}
  end

  @impl true
  def handle_call({:write, data}, _from, state) do
    UART.write(state.uart, data)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:circuits_uart, _port, line}, state) do
    send(Service.ETLPipeline, {:serial_line, line})
    {:noreply, state}
  end
end
