defmodule BitcoinPriceScraper.Jwt do
  use Joken.Config

  def sign!(payload) when is_map(payload) do
    generate_and_sign!(payload, signer())
  end

  def signer() do
    # upbit에서 권장하는 HS256 알고리즘 사용
    Joken.Signer.create("HS256", Application.get_env(:bitcoin_price_scraper, :upbit_secret_key))
  end
end
