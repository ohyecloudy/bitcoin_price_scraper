defmodule BitcoinPriceScraper.QuotationDemander do
  use GenStage

  def start_link(from, to, step) do
    opts = %{current_datetime: from, to_datetime: to, step: step}
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:producer, opts}
  end

  def handle_demand(demand, state) when demand > 0 do
    {events, state} =
      Enum.reduce(1..demand, {[], state}, fn _, {events, state} ->
        # to_datetime 보다 작을 때만 event를 생산한다
        if NaiveDateTime.compare(state.current_datetime, state.to_datetime) == :lt do
          # step을 초로 변환해서 더하고 to_datetime을 넘지 않게 한다
          next =
            min_dt(NaiveDateTime.add(state.current_datetime, state.step * 60), state.to_datetime)

          {[next | events], %{state | current_datetime: next}}
        else
          {events, state}
        end
      end)

    {:noreply, Enum.reverse(events), state}
  end

  defp min_dt(lhs, rhs) when is_struct(lhs, NaiveDateTime) and is_struct(rhs, NaiveDateTime) do
    case NaiveDateTime.compare(lhs, rhs) do
      :gt -> rhs
      _ -> lhs
    end
  end
end
