# https://hexdocs.pm/gen_stage/GenStage.html 예제 코드를 참고함

defmodule BitcoinPriceScraper.RateLimiter do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(_) do
    {:consumer, %{}}
  end

  def handle_subscribe(:producer, opts, from, producers) do
    limits_per_second = Keyword.fetch!(opts, :limits_per_second)

    producers =
      producers
      |> Map.put(from, limits_per_second)
      |> ask_and_schedule(from)

    # :manual을 리턴해 생산자(producer)에 요구(demand)를 보내는 걸 직접 컨트롤한다.
    {:manual, producers}
  end

  def handle_events(events, _from, producers) do
    # consume!
    IO.puts("#{inspect(NaiveDateTime.utc_now())}: #{inspect(events, charlists: true)}")

    {:noreply, [], producers}
  end

  def handle_info({:ask, from}, producers) do
    {:noreply, [], ask_and_schedule(producers, from)}
  end

  defp ask_and_schedule(producers, from) do
    case producers do
      %{^from => limits_per_second} ->
        # 이벤트를 요구한다. :manual 모드일 때는 GenStage.ask/2 함수를 호출해서 직접 요구해야 한다
        GenStage.ask(from, limits_per_second)
        # 초당 호출 개수 제한이 있으므로 1초 스케쥴링을 한다
        Process.send_after(self(), {:ask, from}, :timer.seconds(1))
        producers

      %{} ->
        producers
    end
  end
end
