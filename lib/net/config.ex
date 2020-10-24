defmodule Net.Config do
  # TODO:
  #
  # - Add more default bootstrap nodes
  # - Allow network topology to be persisted
  @derive [Poison.Decoder]
  defstruct net_name: "main", bootstrap_nodes: ["exnode.dowlandaiello.com"]

  @doc """
  Generates a config from the file at the given path. If the file is unable
  to be decoded or does not exist, :err is returned.
  """
  def parse(f) do
    case res = File.read(f) do
      {:ok, contents} -> Poison.decode!(contents)
      _ -> res
    end
  end
end
