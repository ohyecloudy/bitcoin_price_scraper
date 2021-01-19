defmodule BitcoinPriceScraper.JwtAuth do
  alias BitcoinPriceScraper.Jwt

  @behaviour Tesla.Middleware

  @impl Tesla.Middleware
  def call(env, next, _options) do
    env
    |> add_auth_header()
    |> Tesla.run(next)
  end

  defp add_auth_header(env) do
    payload = %{
      access_key: Application.get_env(:bitcoin_price_scraper, :upbit_access_key),
      nonce: UUID.uuid4()
    }

    payload =
      if Enum.empty?(env.query) do
        payload
      else
        query_hash =
          :crypto.hash(:sha256, Tesla.encode_query(env.query))
          |> Base.encode16()

        Map.merge(
          payload,
          %{
            query_hash: query_hash,
            query_hash_alg: "SHA512"
          }
        )
      end

    jwt_token = Jwt.sign!(payload)
    put_in(env.headers, [{"authorization", "Bearer #{jwt_token}"} | env.headers])
  end
end
