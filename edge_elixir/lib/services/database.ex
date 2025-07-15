defmodule Service.Database do
  @moduledoc """
  GenServer for managing SQLite database connection and operations.
  """
  use GenServer
  require Logger
  alias Exqlite.Sqlite3

  @table_name "sensor_data"
  @create_table_query """
  CREATE TABLE IF NOT EXISTS #{@table_name} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lpg REAL,
    ch4 REAL,
    co REAL,
    temperature REAL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
  );
  """

  # MARK: Client API

  @doc """
  Starts the GenServer with the given database path.
  """
  @doc db_path: "The path to the SQLite database file."
  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(db_path) do
    Logger.info("> GEN: Starting DB server | Database at #{db_path}")
    GenServer.start_link(__MODULE__, db_path, name: __MODULE__)
  end

  @doc """
  Stops the Database GenServer.
  """
  @spec stop(term()) :: :ok | {:error, term()}
  def stop(reason) do
    Logger.info("> GEN: Stopping DB server | Reason: #{inspect(reason)}")
    GenServer.stop(__MODULE__, reason)
  end

  @doc """
  Inserts a new sensor data record into the database.
  """
  @spec insert(Models.Readings.t()) :: :ok | {:error, term()}
  def insert(%Models.Readings{} = data) do
    GenServer.call(__MODULE__, {:insert, data})
  end

  @doc """
  Selects the `n` latest sensor data records.
  """
  @spec select(non_neg_integer()) :: {:ok, list(map())} | {:error, term()}
  @doc n: "The maximum number of records to return (default is 10)."
  def select(n \\ 10) do
    GenServer.call(__MODULE__, {:select, n})
  end

  # MARK: Server Callbacks

  @impl true
  def init(db_path) do
    with {:ok, conn} <- Sqlite3.open(db_path),
         :ok <- Sqlite3.execute(conn, @create_table_query) do
      {:ok, conn}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def terminate(_reason, conn) do
    Sqlite3.close(conn)
    :ok
  end

  @impl true
  def handle_call({:insert, %Models.Readings{lpg: lpg, ch4: ch4, co: co, temperature: temperature}}, _from, conn) do
    query = """
    INSERT INTO #{@table_name} (lpg, ch4, co, temperature)
    VALUES (?, ?, ?, ?);
    """

    result =
      with {:ok, stmt} <- Sqlite3.prepare(conn, query),
           :ok <- Sqlite3.bind(stmt, [lpg, ch4, co, temperature]),
           :done <- Sqlite3.step(conn, stmt),
           :ok <- Sqlite3.release(conn, stmt) do
        :ok
      else
        error -> error
      end

    {:reply, result, conn}
  end

  @impl true
  def handle_call({:select, limit}, _from, conn) do
    query = """
    SELECT id, lpg, ch4, co, temperature, timestamp
    FROM #{@table_name} ORDER BY timestamp DESC LIMIT ?;
    """

    result =
      with {:ok, stmt} <- Sqlite3.prepare(conn, query),
           :ok <- Sqlite3.bind(stmt, [limit]),
           {:ok, rows} <- Sqlite3.fetch_all(conn, stmt),
           :ok <- Sqlite3.release(conn, stmt) do
        {:ok, Enum.map(rows, &row_to_map/1)}
      else
        error -> error
      end

    {:reply, result, conn}
  end

  # MARK: Private Functions

  defp row_to_map(row) do
    %{
      id: Enum.at(row, 0),
      lpg: Enum.at(row, 1),
      ch4: Enum.at(row, 2),
      co: Enum.at(row, 3),
      temperature: Enum.at(row, 4),
      timestamp: Enum.at(row, 5)
    }
  end
end
