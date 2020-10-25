defmodule Net.PeerWorker do
  @moduledoc """
  A process that manages communications with a peer.
  """

  use Task
  require Logger

  def start_link(conn) do
    Task.start_link(fn -> run(conn) end)
  end

  def run(conn) do
    # In case the remote peer disconnects, cache addr & port
    {:ok, [{addr, port}]} = :inet.peernames(conn)

    case :gen_tcp.recv(conn, 0) do
      {:ok, msg} -> IO.inspect msg
      {:error, :closed} ->
        Logger.warn("connection closed by remote peer #{inspect addr}:#{port}")
      e -> Logger.warn("#{inspect e}")
    end
  end

  @doc """
  Publishes the given transaction.
  """
  def publish_transaction(tx, conn) do
    case :gen_tcp.send(conn, "PUB_TX #{Core.Tx.str_repr(tx)}") do
      {error, reason} -> {:err, {error, reason}}
      _ok -> {:ok}
    end
  end

  @doc """
  Requests an up-to-date peerlist.
  """
  def request_peerlist(max_peers, conn) do
    case :gen_tcp.send(conn, "REQ_PS #{max_peers}") do
      {error, reason} -> {:err, {error, reason}}
      _ok -> {:ok}
    end
  end
end
