defmodule Net.Listener.Tcp do
  @moduledoc """
  A process that listens on a given TCP port for connections from its peers.
  """

  use GenServer
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(port) do
    # Start listening
    {:ok, socket} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :line,
        active: false,
        reuseaddr: true
      ])

    Logger.info("accepting connections via TCP:#{port}")
    accept_conn(socket)

    {:ok, socket}
  end

  defp accept_conn(socket) do
    {:ok, conn} = :gen_tcp.accept(socket)
    handle_conn(conn)
    accept_conn(socket)
  end

  defp handle_conn(conn) do
  end
end
