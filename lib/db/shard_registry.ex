defmodule Db.ShardRegistry do
  @moduledoc """
  Provides utility functions for dealing with cross-shard address spaces and
  keeps track of all running shards.
  """

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(n_shards) do
    hasher = Math.log(n_shards, 58)
             |> ceil
             |> fn unique_chars ->
                fn key -> 
                  key
                  |> String.slice(1..unique_chars)
                  |> String.codepoints
                  |> Enum.reduce(fn c, acc -> acc + ?c)
                end
              end
    end

    {:ok, {[], n_shards, hasher}}
  end

  @impl true
  def handle_call({:register_shards, new_shards}, _from, {shards, n_shards, hasher}) do
    {:noreply, {new_shards, n_shards}}
  end

  @impl true
  def handle_call({:shard_for_addr, address}, _from, {shards, n_shards, hasher}) do
    {:reply, shards[hasher(address) % n_shards]}
  end

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
