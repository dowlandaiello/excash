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
    spec = {}
  end

  @doc """
  Used to establish an outgoing connect (e.g., during bootstrapping).
  """
  def start_child(addr, port) do
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
