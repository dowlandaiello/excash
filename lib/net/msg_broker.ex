defmodule Net.MsgBroker do
  @moduledoc """
  A process that supervises outgoing connections to peers on the network and
  facilitates the broadcast of messages to such peers.
  """

  use DynamicSupervisor
  require Logger

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Used by listener/tcp.ex, wherein connections are ACCEPTED, rather than
  being made on an outgoing basis.
  """
  def start_child(conn) do
    DynamicSupervisor.start_child(__MODULE__, {Net.PeerWorker, conn})
  end

  @doc """
  Used to establish an outgoing connect (e.g., during bootstrapping).
  """
  def start_child(addr, port) do
    case :gen_tcp.connect(to_charlist(addr), port, [:binary, :inet, active: false], 500) do
      {:ok, socket} -> start_child(socket)
      e -> e
    end
  end

  @impl true
  def init(:ok) do
    Logger.info("message broker started successfully (#{inspect(self())})")

    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
