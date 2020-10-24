defmodule Net.Listener.Tcp do
  @moduledoc """
  A process that listens on a given TCP port for connections from its peers.
  """

  use GenServer

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end
end
