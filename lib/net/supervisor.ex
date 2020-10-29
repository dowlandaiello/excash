defmodule Net.Supervisor do
  @moduledoc """
  Implements a supervisor for the local node connected to an excash network -
  the "hub" of excashd.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init({opts, _net_cfg}) do
    children = [
      Net.MsgBroker,
      Net.Discovery.PeerList,
      {Net.Listener.Tcp, opts[:port]},
      {Db.ShardRegistry, opts[:n_shards]}
    ]

    # Spawn a worker process to serve each shard, where each shard is a process
    # with an id of Shard${i}
    Logger.info("spawning #{opts[:n_shards]} shard workers...")

    children =
      Enum.reduce(
        0..opts[:n_shards],
        children,
        &[
          Supervisor.child_spec({Db.Shard, {%{}}}, id: "Shard#{&1}")
          | &2
        ]
      )

    Supervisor.init(children, strategy: :one_for_one)
  end
end
