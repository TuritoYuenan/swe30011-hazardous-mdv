defmodule Service.ETLPipeline do
  @moduledoc """
  ETL (Extract, Transform, Load) module for processing data from a serial port.
  """
  use GenServer
  require Logger

  @flush_lines 5

  # MARK: Client API

  @doc """
  Starts the ETL GenServer.
  """
  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_) do
    Logger.info("> GEN: Starting ETL server")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Stops the ETL GenServer.
  """
  @spec stop(term()) :: :ok | {:error, term()}
  def stop(reason) do
    Logger.info("> GEN: Stop ETL server | #{inspect(reason)}")
    GenServer.stop(__MODULE__, reason)
  end

  # MARK: Server Callbacks

  @impl true
  def init(state) do
    {:ok, Map.put(state, :flush_count, @flush_lines)}
  end

  @impl true
  def handle_info({:serial_line, _line}, %{flush_count: count} = state) when count > 0 do
    # Ignore this line, decrement flush_count
    {:noreply, %{state | flush_count: count - 1}}
  end

  @impl true
  def handle_info({:serial_line, line}, state) do
    case transform(line, :line) do
      {:ok, map} -> load(map)
      :error -> Logger.warning(">> ETL: Discarded faulty line: #{inspect(line)}")
    end
    {:noreply, state}
  end

  # MARK: Private Functions

  @spec transform(String.t(), atom()) :: {:ok, map} | :error
  defp transform(line, :line) do
    try do
      map =
        line
        |> String.trim()
        |> String.split(",")
        |> Enum.map(&transform(&1, :pair))
        |> Enum.into(%{})

      {:ok, struct(Models.Readings, map)}
    rescue
      _ -> :error
    end
  end

  defp transform(pair, :pair) do
    try do
      [k, v] = String.split(pair, ":")
      {String.to_atom(String.downcase(k)), String.to_float(v)}
    rescue
      _ -> :error
    end
  end

  @spec load(map()) :: :ok | :noop
  defp load(map) do
    Logger.info(">> ETL: Loading data: #{inspect(map)}")
    Service.Database.insert(map)
  end
end
