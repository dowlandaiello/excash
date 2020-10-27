defmodule Net.Listener.Tcp do
  @moduledoc """
  A process that listens on a given TCP port for connections from its peers.
  """

  use Task
  require Logger

  def start_link(port) do
    Task.start_link(fn -> run(port) end)
  end

  def run(port) do
    # Start listening
    {:ok, socket} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :line,
        active: false,
        reuseaddr: true
      ])

    Logger.info("accepting connections via TCP:#{port} (#{inspect(self())})")
    accept_conn(socket)
  end

  defp accept_conn(socket) do
    {:ok, conn} = :gen_tcp.accept(socket)
    handle_conn(conn)
    accept_conn(socket)
  end

  defp handle_conn(conn) do
    {:ok, [{addr, port}]} = :inet.peernames(conn)

    Logger.info(
      "connection opened to peer #{
        Net.Discovery.PeerList.addr_to_str(addr, port)
      }"
    )

    Net.MsgBroker.start_child(conn)
    GenServer.call(Net.Discovery.PeerList, {:push, {addr, port}})
  end
end
