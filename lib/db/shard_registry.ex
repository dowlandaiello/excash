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

    {:ok, {%{}, n_shards, hasher}}
  end

  @impl true
  def handle_call(
        {:register_shards, new_shards},
        _from,
        {_shards, n_shards, hasher}
      ) do
    {:reply, new_shards, {new_shards, n_shards, hasher}}
  end

  @impl true
  def handle_call({:shard_for_addr, address}, _from, {shards, n_shards, hasher}) do
    {:reply, shards |> elem(rem(hasher.(address), n_shards)),
     {shards, n_shards, hasher}}
  end

  @impl true
  def handle_call({:balance_stream}, _from, {shards, n_shards, hasher}) do
    {:reply,
     shards
     |> Map.values()
     |> Stream.map(&GenServer.call(&1, :all_balances))
     |> Stream.concat(), {shards, n_shards, hasher}}
  end

  @doc """
  Gets a list of shard workers on the local node.
  """
  def walk_all_shards() do
    Net.Supervisor
    |> Supervisor.which_children()
    |> Stream.filter(&(elem(&1, 0) |> is_binary))
    |> Stream.filter(&(elem(&1, 0) |> String.contains?("Shard")))
    |> Stream.map(&elem(&1, 1))
    |> Stream.with_index()
    |> Enum.reduce(%{}, fn {x, i}, acc -> acc |> Map.put(i, x) end)
  end
end
