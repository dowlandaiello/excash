defmodule Net.Discovery.Bootstrap do
  @moduledoc """
  Implements peer discovery through bootstrap node traversal.
  """

  @doc """
  Discovers all available peers through the given bootstrap node.
  Connects to each of the discovered peers via the message broker.
  """

  require Logger

  def discover_extrinsic_peers(bootstrap_nodes) do
    # Connect to each of the provided nodes
    Enum.each(bootstrap_nodes, fn %{"addr" => addr, "port" => port} ->
      case Net.MsgBroker.start_child(addr, port) do
        {:ok, p_worker} ->
          Logger.info(
            "established message broker connection to bootstrap node: #{addr}:#{
              port
            }"
          )

        e ->
          Logger.warn(
            "failed to connect to bootstrap node #{addr}:#{port} - skipping: #{inspect(e)}"
          )
      end
    end)
  end
end
