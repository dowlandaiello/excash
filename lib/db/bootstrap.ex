defmodule Db.Bootstrap do
  @moduledoc """
  Bootstraps the global state from the connected peers.
  """

  @doc """
  Requests the latest state from all connected peers in an asynchronous fashion.
  """
  def synchronize_state() do
    # Tell each connected peer to fetch us the latest state
    DynamicSupervisor.which_children(Net.MsgBroker)
    |> Enum.each(
      &(
        # Let each connected peer respond on their own time - don't let a
        # single blocked socket slow down sync process
        Task.async fn ->
          &1
          # {Process, Pid}
          #           ^ we want this
          |> elem(1)
          # Find the broadcaster in a peer worker
          |> Supervisor.which_children
          |> Enum.find(fn x -> elem(x, 0) == Net.PeerWorker.Broadcaster end)
          # See above on PIDs
          |> elem(1)
          |> GenServer.call(:request_active_addresses)
        end
      )
    )
  end
end
