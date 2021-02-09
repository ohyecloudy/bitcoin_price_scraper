defmodule BitcoinPriceScraper do
  alias BitcoinPriceScraper.{QuotationDemander, RateLimiter, Metrics}

  def scrap() do
    Metrics.start()

    to = NaiveDateTime.utc_now()
    # 30 days
    from = NaiveDateTime.add(to, -60 * 60 * 24 * 30)
    # 시세(quotation) API 요청시 캔들 개수 최대값: 200
    # https://docs.upbit.com/reference#분minute-캔들-1
    {:ok, producer} = QuotationDemander.start_link(from, to, 200)
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
