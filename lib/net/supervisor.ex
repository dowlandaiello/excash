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

    shards =
      Enum.reduce(
        0..opts[:n_shards],
        [],
        &[
          Supervisor.child_spec({Db.Shard, {%{}}}, id: "Shard#{&1}")
          | &2
        ]
      )

    # Keep track of the shards with ShardRegistry
    init_res =
      Supervisor.init(Enum.concat(children, shards), strategy: :one_for_one)

    IO.puts()
    GenServer.call(Db.ShardRegistry, {:register_shards, shards})

    init_res
  end
end
