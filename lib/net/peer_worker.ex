defmodule Net.PeerWorker do
  @moduledoc """
  A process that manages communications with a peer.
  """

  use Supervisor

  def start_link(conn) do
    Supervisor.start_link(__MODULE__, conn)
  end

  @impl true
  def init(conn) do
    # In case the remote peer disconnects, cache addr & port
    {:ok, [{addr, port}]} = :inet.peernames(conn)

    children = [
      {Net.PeerWorker.Broadcaster, conn},
      {Net.PeerWorker.Listener, [conn, {addr, port}]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Net.PeerWorker.Broadcaster do
  use GenServer

  def start_link(conn) do
    GenServer.start_link(__MODULE__, conn)
  end

  @impl true
  def init(conn) do
    {:ok, conn}
  end

  @impl true
  def handle_call({:publish_transaction, tx}, _from, conn) do
    case :gen_tcp.send(conn, "PUB_TX #{Core.Tx.str_repr(tx)}") do
      {error, reason} -> {:reply, {:err, {error, reason}}}
      _ok -> {:reply, {:ok}, conn}
    end
  end

  @impl true
  def handle_call({:request_peerlist, max_peers}, _from, conn) do
    case :gen_tcp.send(conn, "REQ_PS #{max_peers}") do
      {error, reason} -> {:reply, {:err, {error, reason}}}
      _ok -> {:reply, {:ok}, conn}
    end
  end
end

defmodule Net.PeerWorker.Listener do
  use Task
  require Logger

  def start_link([conn, {addr, port}]) do
    Task.start_link(fn -> run(conn, {addr, port}) end)
  end

  def run(conn, {addr, port}) do
    case :gen_tcp.recv(conn, 0) do
      {:ok, msg} ->
        IO.inspect(msg)

      {:error, :closed} ->
        Logger.warn("connection closed by remote peer #{inspect(addr)}:#{port}")

      e ->
        Logger.warn("#{inspect(e)}")
    end
  end
end
