defmodule Consensus.BootstrapBeacon do
  @moduledoc """
  Implements a truth mechanism used to determine the average global state--the
  "true" state to which the node should bootstrap.
  """

  use DynamicSupervisor
end
