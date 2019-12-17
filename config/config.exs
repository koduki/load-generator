use Mix.Config

config :logger,
  backends: [{LoggerFileBackend, :error_log}]

config :logger, :error_log,
  path: "/var/log/loadgen/loadgen.log"
