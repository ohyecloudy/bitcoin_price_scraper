defmodule BitcoinPriceScraper.QuotationDemander do
  use GenStage

  def start_link(number) do
    GenStage.start_link(__MODULE__, number)
  end

  def init(counter) do
    {:producer, counter}
  end

  def handle_demand(demand, counter) when demand > 0 do
    # 이벤트 요구 개수 이하를 랜덤하게 생산한다
    # [1, demand]
    demand = :rand.uniform(demand)
    events = Enum.to_list(counter..(counter + demand - 1))
    {:noreply, events, counter + demand}
  end
end
