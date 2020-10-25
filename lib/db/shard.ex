defmodule Db.Shard do
  @moduledoc """
  Implements a key-value store representing the balances of 1/n of the vali
  address space, where n is the shard count.
  """

  use GenServer

  def start_link({state}) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(balances) do
    {:ok, balances}
  end

  @impl true
  def handle_call({:put_balance, address, balance}, _from, balances) do
    {:noreply, Map.put(balances, address, balance)}
  end

  @impl true
  def handle_call({:get_balance, address}, _from, balances) do
    {:reply, balances[address], balances}
  end
end
