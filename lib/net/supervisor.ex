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
  def init(opts) do
    children = [
      {Net.Listener.Tcp, opts[:port]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
