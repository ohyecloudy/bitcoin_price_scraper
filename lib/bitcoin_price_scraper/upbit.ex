defmodule BitcoinPriceScraper.Upbit do
  use Tesla
  alias BitcoinPriceScraper.Jwt

  plug Tesla.Middleware.BaseUrl, "https://api.upbit.com/v1"
  plug Tesla.Middleware.JSON

  # 최대 요청 캔들 카운트
  # https://docs.upbit.com/reference#분minute-캔들-1
  @max_candle_count 200

  def markets() do
    payload = %{
      access_key: Application.get_env(:bitcoin_price_scraper, :upbit_access_key),
      nonce: UUID.uuid4()
    }

    jwt_token = Jwt.sign!(payload)

    get("market/all", headers: [{"authorization", "Bearer #{jwt_token}"}])
  end

  def candles(market, to, count \\ 200) do
    query = %{
      market: market,
      to: to_string(NaiveDateTime.truncate(to, :second)),
      count: min(count, @max_candle_count)
    }

    query_hash =
      :crypto.hash(:sha256, Tesla.encode_query(query))
      |> Base.encode16()

    payload = %{
      access_key: Application.get_env(:bitcoin_price_scraper, :upbit_access_key),
      nonce: UUID.uuid4(),
      query_hash: query_hash,
      query_hash_alg: "SHA512"
    }

    jwt_token = Jwt.sign!(payload)

    get("candles/minutes/1",
      query: query,
      headers: [{"authorization", "Bearer #{jwt_token}"}]
    )
  end
end
