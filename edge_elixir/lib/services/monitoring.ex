defmodule Service.Monitoring do
  @moduledoc """
  A GenServer that monitors the database and serial processes.
  It periodically performs tasks using the provided PIDs for database and serial communication.
  """
  use GenServer
  require Logger

  @interval_seconds 4

  # MARK: Client API

  @doc """
  Starts the Monitoring GenServer with the given state.
  """
  @doc args: "PIDs of the database and serial processes."
  @spec start_link(%{db: float(), serial: float()}) :: GenServer.on_start()
  def start_link(args) do
    Logger.info("> GEN: Starting MON server", args)
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Stops the Monitoring GenServer.
  """
  @spec stop(term()) :: :ok | {:error, term()}
  def stop(reason) do
    Logger.info("> GEN: Stop MON server", reason)
    GenServer.stop(__MODULE__, reason)
  end

  # MARK: Server Callbacks

  @impl true
  def init(args) do
    schedule_work()
    {:ok, args}
  end

  @impl true
  def handle_info(:work, state) do
    Service.Database.select(10)
    |> case do
      {:ok, []} ->
        Logger.info(">> MON: Cannot detect gas leak, no readings found")

      {:ok, readings} ->
        if detect_gas_leak(readings) do
          Logger.warning(">> MON: Gas leak detected! Engaging response system")
          Service.SerialConnection.write(~c"2")
        else
          Logger.info(">> MON: No gas leak detected. Disengaging response system")
          Service.SerialConnection.write(~c"0")
        end

      {:error, reason} ->
        Logger.warning(">> MON: Error fetching readings from database", reason)
    end

    schedule_work()
    {:noreply, state}
  end

  # MARK: Private Functions

  @spec schedule_work() :: :ok
  defp schedule_work() do
    Process.send_after(self(), :work, :timer.seconds(@interval_seconds))
  end

  @doc readings: "list of maps, each %{lpg: float, ch4: float, co: float, temp: float}"
  @spec detect_gas_leak(list()) :: boolean()
  def detect_gas_leak(readings) do
    thresholds = %{lpg: 1000, ch4: 1000, co: 35}
    gases = [:lpg, :ch4, :co]

    Enum.any?(gases, fn gas ->
      # List of values for the current gas
      values = Enum.map(readings, & &1[gas])

      # Last value for Threshold detection
      last = List.last(values)

      # Average and standard deviation for Sudden spike detection
      avg = Enum.sum(values) / length(values)

      stddev =
        :math.sqrt(Enum.sum(Enum.map(values, fn v -> :math.pow(v - avg, 2) end)) / length(values))

      # Threshold or sudden spike
      last > thresholds[gas] or last - avg > 2 * stddev
    end)
  end
end
