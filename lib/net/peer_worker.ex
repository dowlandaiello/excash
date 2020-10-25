defmodule Net.PeerWorker do
  @moduledoc """
  A process that manages communications with a peer.
  """

  use GenServer

  def start_link(conn) do
    GenServer.start_link(__MODULE__, conn)
  end

  @impl true
  def init(conn) do
    {:ok, conn}
  end

  @doc """
  Publishes the given transaction.
  """
  @impl true
  def handle_call({:publish_transaction, tx}, _from, conn) do
    case :gen_tcp.send(conn, "PUB_TX #{Core.Tx.str_repr(tx)}") do
      {error, reason} -> {:reply, {:err, {error, reason}}, conn}
      _ok -> {:reply, :ok, conn}
    end
  end
end
