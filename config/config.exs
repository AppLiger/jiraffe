import Config

config :tesla, adapter: {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}

import_config "#{config_env()}.exs"
