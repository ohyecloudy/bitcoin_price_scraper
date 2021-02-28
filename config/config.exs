import Config

config :bitcoin_price_scraper,
  upbit_access_key: "SUPER_ACCESS_KEY",
  upbit_secret_key: "SUPER_SECRET_KEY",
  scrap_days: 4 * 365

# https://github.com/deadtrickster/prometheus-httpd/blob/master/doc/prometheus_httpd.md
config :prometheus, :prometheus_http,
  path: String.to_charlist("/metrics"),
  format: :auto,
  port: 8081

if File.exists?("config/#{Mix.env()}.secret.exs") do
  import_config "#{Mix.env()}.secret.exs"
end
