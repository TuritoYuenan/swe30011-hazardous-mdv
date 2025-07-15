import Config

config :logger, :default_formatter,
  level: :info,
  format: "$time $metadata[$level] $message\n"
