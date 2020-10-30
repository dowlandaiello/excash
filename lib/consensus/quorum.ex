defmodule Consensus.Quorum do
  @moduledoc """
  Implements a truth-finding mechanism based on values of d (duration callback) and p
  (percentage).
  """

  use GenServer

  @impl true
  def init({d, p, hasher}) do
    {:ok, {%{}, {d, p, hasher}}}
  end

  @impl true
  def handle_cast({:put, truth_part}, {parts, {d, p, hasher}}) do
    {:noreply, %{hasher(truth_part) | parts}}
  end
end
