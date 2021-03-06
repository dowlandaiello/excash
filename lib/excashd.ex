defmodule Excashd do
  require Logger

  def main(args) do
    options = [
      switches: [
        datadir: :string,
        port: :integer,
        n_shards: :integer,
        max_peers: :integer
      ],
      aliases: [d: :datadir, p: :port, n: :n_shards]
    ]

    defaults = [
      {:datadir, File.cwd!() <> "/excash_data"},
      {:port, 25565},
      {:n_shards, 512},
      {:max_peers, 64}
    ]

    opts = Keyword.merge(defaults, elem(OptionParser.parse(args, options), 0))
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
          safe_cfg = Map.merge(%Net.Config{}, cfg)

          Logger.info("starting network supervisor...")

          # Start the node supervisor
          {:ok, sup} = Net.Supervisor.start_link({opts, safe_cfg})

          # Register shards for later use
          shards = Db.ShardRegistry.walk_all_shards()
          GenServer.call(Db.ShardRegistry, {:register_shards, shards})

          Logger.info("connecting to network...")

          Net.Discovery.Bootstrap.discover_extrinsic_peers(
            safe_cfg.bootstrap_nodes,
            opts[:max_peers]
          )

          Db.Bootstrap.synchronize_state()

          Logger.info("excashd core started successfully (#{inspect(sup)})!")

          block()
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

  def block() do
    Process.sleep(:infinity)
  end
end
