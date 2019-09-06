import Config

if Mix.env == :test do
  config :tesla, adapter: Tesla.Mock
end