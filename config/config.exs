import Config

config :bitcoin_price_scraper,
  upbit_access_key: "SUPER_ACCESS_KEY",
  upbit_secret_key: "SUPER_SECRET_KEY"

if File.exists?("config/#{Mix.env()}.secret.exs") do
  import_config "#{Mix.env()}.secret.exs"
end
