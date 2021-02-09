defmodule BitcoinPriceScraper.Metrics do
  alias BitcoinPriceScraper.Metrics.Handler

  def start() do
    :prometheus_httpd.start()
    Handler.start()
  end
end
