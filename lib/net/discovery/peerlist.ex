defmodule Net.Discovery.PeerList do
  @moduledoc """
  A list of IP addresses and ports representing the connected peers.
  """

  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    {:ok, MapSet.new()}
  end

  # Pushes a peer to the list of connected peers.
  @impl true
  def handle_call({:push, {addr, port}}, _from, peerlist) do
    peerlist =
      MapSet.put(
        peerlist,
        addr_to_str(if(addr == "localhost", do: "127.0.0.1", else: addr), port)
      )

    {:reply, peerlist, peerlist}
  end

  # Gets a list of connected peers.
  @impl true
  def handle_call(:get, _from, peerlist) do
    {:reply, peerlist, peerlist}
  end

  # Removes a peer from the peer list
  @impl true
  def handle_call({:remove, {addr, port}}, _from, peerlist) do
    peerlist =
      MapSet.delete(
        peerlist,
        addr_to_str(if(addr == "localhost", do: "127.0.0.1", else: addr), port)
      )

    {:reply, peerlist, peerlist}
  end

  def addr_to_str(addr, port) when is_binary(addr) or is_list(addr) do
    "#{addr}:#{port}"
  end

  @doc """
  Converts the given peernames to a string.
  """
  def addr_to_str({a, b, c, d}, port) do
    "#{a}.#{b}.#{c}.#{d}:#{port}"
  end

  # Conversion for ipv6 addrs
  def addr_to_str(addr, port) when is_tuple(addr) and tuple_size(addr) === 8 do
    Enum.map(0..8, fn x -> "#{elem(addr, x)}:" end) <> ":#{port}"
  end

  @doc """
  Converts the given string peername parts to an address string.
  """
  def addr_str_parts_to_addr([addr, port]) do
    [addr, String.to_integer(port)]
  end
end
