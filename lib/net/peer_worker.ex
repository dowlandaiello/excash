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

  @doc """
  Sends the given transaction to the peer handled by the worker.
  """
  @impl true
  def handle_call({:publish_transaction, tx}, _from, conn) do
    case :gen_tcp.send(conn, "PUB_TX #{Core.Tx.str_repr(tx)}\n") do
      :ok -> {:reply, {:ok}, conn}
      {error, reason} -> {:reply, {:err, {error, reason}}}
    end
  end

  # Requests an update peerlist from the peer handled by the worker.
  @impl true
  def handle_call({:request_peerlist, max_peers}, _from, conn) do
    case :gen_tcp.send(conn, "REQ_PS #{max_peers}\n") do
      :ok -> {:reply, {:ok}, conn}
      {error, reason} -> {:reply, {:err, {error, reason}}}
    end
  end

  # Requests all recorded balances in chunks
  @impl true
  def handle_call(:request_all_balances, _from, conn) do
    case :gen_tcp.send(conn, "REQ_AB\n") do
      :ok -> {:reply, {:ok}, conn}
      {error, reason} -> {:reply, {:err, {error, reason}}}
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
        case String.split(msg, " ") do
          # HANDLE REQUEST: PEERLIST
          ["REQ_PS", max_peers] ->
            Logger.info(
              "peerlist requested by remote peer #{
                Net.Discovery.PeerList.addr_to_str(addr, port)
              }"
            )

            # Send them our peerlist by joining max_peers together with commas
            peerlist = GenServer.call(Net.Discovery.PeerList, :get)

            :ok = :gen_tcp.send(
              conn,
              "RES_PS #{
                Enum.join(
                  Stream.take(
                    peerlist,
                    String.to_integer(String.trim(max_peers))
                  ),
                  ","
                )
              }"
            )

          # HANDLE RESP: PEERLIST
          ["RES_PS", peerlist] ->
            # Cache a copy of the current peerlist so that we can filter out duplicates
            current_peerlist = GenServer.call(Net.Discovery.PeerList, :get)

            # Convert node:address,address:jaosdf::123 to [node, address], [address:jaosdf, 123]
            String.trim(peerlist)
            |> String.split(",")
            |> Stream.filter(&(&1 != ""))
            # Remove duplicates
            |> Stream.uniq()
            # Split ipv::6 and ipv:4 addresses by their respective delims
            |> Stream.map(
              # Use : as a delim for ipv4, and :: for ipv6
              &(&1
                |> String.split(
                  if &1
                     |> String.graphemes()
                     |> Enum.count(fn elem -> elem == ":" end) > 1,
                     do: "::",
                     else: ":"
                )
                |> Net.Discovery.PeerList.addr_str_parts_to_addr())
            )
            # Filter out any peers that are clearly ourselves
            |> Stream.filter(fn [remote_addr, remote_port] ->
              remote_addr != addr or remote_port != port
            end)
            # And filter out any peers that are already connected
            |> Stream.filter(fn [remote_addr, remote_port] ->
              !Enum.member?(
                current_peerlist,
                Net.Discovery.PeerList.addr_to_str(remote_addr, remote_port)
              )
            end)
            # Add each new node to the peerlist
            |> Enum.each(fn [remote_addr, remote_port] ->
              Task.async(fn ->
                Net.MsgBroker.start_child(remote_addr, remote_port)

                GenServer.call(
                  Net.Discovery.PeerList,
                  {:push, {remote_addr, remote_port}}
                )

                Logger.info(
                  "discovered new peer: #{remote_addr}:#{remote_port}"
                )
              end)
            end)

          # HANDLE REQ: ALL BALANCES
          ["REQ_AB", balances_per_chunk] ->
            # Lazily load all recorded balances and send them over
            Db.AccountRegistry.stream_balances()
            |> Enum.every(
              fn chunk ->
                :ok = :gen_tcp.send(conn, "RES_AB #{Enum.join(chunk, ",")}\n")
              end
            )

            # Done
            :ok = :gen_tcp.send(conn, "DONE\n")

          # HANDLE RES: ALL BALANCES
          ["RES_AB", str_balances] -> 
            IO.inspect str_balances
            String.split(str_accts, ",") 
            |> Stream.filter(&(&1 != ""))
            |> Enum.each(&(IO.inspect &1))

          # CLIENT IS DONE TALKING
          "DONE" -> :ok

          _ ->
            Logger.warn("unhandled request: #{String.trim msg}")
        end

        # When the socket is still open, keep reading
        run(conn, {addr, port})

      {:error, :closed} ->
        Logger.warn(
          "connection closed by remote peer #{
            Net.Discovery.PeerList.addr_to_str(addr, port)
          }; removing from peer list"
        )

        GenServer.call(Net.Discovery.PeerList, {:remove, {addr, port}})

      # Remove the peer from the peerlist

      e ->
        Logger.warn("#{inspect(e)}")
    end
  end
end
