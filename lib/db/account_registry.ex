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
end
