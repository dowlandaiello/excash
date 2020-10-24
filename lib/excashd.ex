defmodule Excashd do
  def main(args) do
    # Available excashd flags are:
    #
    # --datadir (-d): the root directory of the daemon - where persistent data
    #   will be kept and where the network.json file will be read from
    options = [switches: [datadir: :string], aliases: [d: :datadir]]
    defaults = [:datadir, File.cwd! <> "excash_data"]

    {opts, _, _} = OptionParser.parse(args, options) |> hd |> Keyword.merge(defaults)
    net_cfg = Net.Config.parse(options[:datadir] <> "network.json")

    IO.inspect net_cfg
  end
end
