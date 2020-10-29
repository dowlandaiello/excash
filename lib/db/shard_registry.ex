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
    unique_chars =
      Math.log(n_shards, 58)
      |> ceil

    hasher = fn key ->
      key
      |> String.slice(0, unique_chars)
      |> String.codepoints()
      |> Enum.reduce(fn ?c, acc -> acc + ?c end)
    end

    {:ok, {[], n_shards, hasher}}
  end

  @impl true
  def handle_call(
        {:register_shards, new_shards},
        _from,
        {_shards, n_shards, hasher}
      ) do
    {:noreply, {new_shards, n_shards, hasher}}
  end

  @impl true
  def handle_call({:shard_for_addr, address}, _from, {shards, n_shards, hasher}) do
    {:reply, shards[rem(hasher.(address), n_shards)],
     {shards, n_shards, hasher}}
  end

  @impl true
  def handle_call({:balance_stream}, _from, {shards, n_shards, hasher}) do
    {:reply,
     shards
     |> Stream.map(&GenServer.call(&1, {:all_balances}))
     |> Stream.concat(), {shards, n_shards, hasher}}
  end
end
