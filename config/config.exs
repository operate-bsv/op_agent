import Config

if Mix.env == :test do
  config :logger, level: :error
  config :tesla, adapter: Tesla.Mock
end
