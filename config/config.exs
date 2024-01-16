import Config

if Mix.env() == :test do
  config :jiraffe, adapter: Tesla.Mock
end
