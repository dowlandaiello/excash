defmodule Net.Supervisor do
  @moduledoc """
  Implements a supervisor for the local node connected to an excash network -
  the "hub" of excashd.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init({opts, net_cfg}) do
    children = [
      {Net.Listener.Tcp, opts[:port]}
    ]

    # Spawn a worker process to serve each shard, where each shard is a process
    # with an id of Shard${i}
    children =
      Enum.reduce(
        0..opts[:n_shards],
        children,
        &[Supervisor.child_spec({Db.Shard, {&1, {}}}, id: "Shard#{&1}") | &2]
      )

    Supervisor.init(children, strategy: :one_for_one)
  end
end
