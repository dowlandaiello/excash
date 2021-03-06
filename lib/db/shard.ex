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
    new_balances = Map.put(balances, address, balance)
    {:reply, new_balances, new_balances}
  end

  @impl true
  def handle_call({:get_balance, address}, _from, balances) do
    {:reply, balances[address], balances}
  end

  @impl true
  def handle_call(:active_addresses, _from, balances) do
    {:reply, Map.keys(balances), balances}
  end

  @impl true
  def handle_call(:all_balances, _from, balances) do
    {:reply, balances, balances}
  end
end
