defmodule Excashd do
  def main(args) do
    require Logger

    # Available excashd flags are:
    #
    # --datadir (-d): the root directory of the daemon - where persistent data
    #   will be kept and where the network.json file will be read from
    options = [
      switches: [datadir: :string, port: :integer, n_shards: :integer],
      aliases: [d: :datadir, p: :port, n: :n_shards]
    ]

    defaults = [
      {:datadir, File.cwd!() <> "/excash_data"},
      {:port, 25565},
      {:n_shards, 512}
    ]

    opts = elem(OptionParser.parse(args, options), 0) |> Keyword.merge(defaults)
    cfg_file = opts[:datadir] <> "/network.json"

    # Warn the user if the config is malformed
    try do
      case Net.Config.parse(cfg_file) do
        {:error, _} ->
          Logger.error(
            "failed to open configuration file: make sure #{cfg_file} exists and is readable by excash."
          )

        # See defaults being applied here in net/config.ex
        cfg ->
          safe_cfg = Map.merge(cfg, %Net.Config{})

          Logger.info("starting network supervisor...")

          # Start the node supervisor
          {:ok, sup} = Net.Supervisor.start_link(opts)
      end
    rescue
      Poison.DecodeError ->
        Logger.error(
          "failed to decode configuration: are you missing `net_name` or `bootstrap_nodes`?"
        )

      Poison.ParseError ->
        Logger.error(
          "failed to parse configuration: make sure network.json contains valid JSON"
        )
    end
  end
end
