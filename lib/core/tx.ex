defmodule Core.Tx do
  defstruct sender: nil,
            recipient: nil,
            value: 0,
            msg: "",
            timestamp: :calendar.universal_time(),
            signature: nil

  # Base58 sha256 hash
  def address_length do
    44
  end

  @doc """
  Derives a alphanumeric representation of the given transaction.
  """
  def str_repr(tx) do
    "#{tx[:sender]} #{tx[:recipient]} #{tx[:value]} '#{tx[:msg]}' #{
      tx[:signature]
    }"
  end

  @doc """
  Derives a signed form of the given transaction from the provided key.
  """
  def sign(tx, key) do
    %{
      tx
      | signature:
          :crypto.sign(
            :ecdsa,
            :sha256,
            :crypto.hash(:sha256, str_repr(tx)),
            key
          )
    }
  end
end
