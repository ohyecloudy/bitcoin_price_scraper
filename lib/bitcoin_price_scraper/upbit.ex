defmodule BitcoinPriceScraper.Upbit do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.upbit.com/v1"
  plug BitcoinPriceScraper.JwtAuth
  plug Tesla.Middleware.JSON

  # 최대 요청 캔들 카운트
  # https://docs.upbit.com/reference#분minute-캔들-1
  @max_candle_count 200

  def markets() do
    get("market/all")
  end

  def candles(market, to, count \\ 200) do
    query = %{
      market: market,
      to: to_string(NaiveDateTime.truncate(to, :second)),
      count: min(count, @max_candle_count)
    }

    get("candles/minutes/1", query: query)
  end
end
