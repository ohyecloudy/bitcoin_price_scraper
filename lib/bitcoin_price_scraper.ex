defmodule BitcoinPriceScraper do
  alias BitcoinPriceScraper.{QuotationDemander, RateLimiter}

  def scrap() do
    {:ok, producer} = QuotationDemander.start_link(1)
    {:ok, consumer} = RateLimiter.start_link()

    GenStage.sync_subscribe(consumer,
      to: producer,
      # 시세(quotation) API 요청수 제한
      # 초당 10, 분당 600
      # https://docs.upbit.com/docs/user-request-guide
      limits_per_second: 10
    )
  end
end
