import Config

config :logger, level: :warning

if Mix.env() == :test do
  config :jiraffe, adapter: Tesla.Mock
end
