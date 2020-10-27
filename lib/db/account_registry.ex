defmodule Db.AccountRegistry do
  @moduledoc """
  Provides utility functions for dealing with cross-shard address spaces.
  """

  @doc """
  Creates a stream over all balances in existence.
  """
  def stream_balances() do
    Net.Supervisor
    |> Supervisor.which_children()
    |> Stream.filter(fn worker ->
      worker
      |> elem(0)
      |> (&(is_binary(&1) and String.contains?(&1, "Shard"))).()
    end)
    |> Stream.map(fn worker ->
      worker
      |> elem(1)
      |> GenServer.call(:all_balances)
    end)
    |> Stream.concat()
  end

  @doc """
  Calculates the number of shards managed locally - used as a caching mechanism.
  """
  def n_shards() do
    # NOTE: The below constant should be updated to reflect the num of static
    # children in supervisor.ex
    Supervisor.count_children(Net.Supervisor) - 3
  end

  @doc """
  Determines the index of the shard holding the given address.
  """
  def corresponding_shard(address, n_shards) do
  end
end
