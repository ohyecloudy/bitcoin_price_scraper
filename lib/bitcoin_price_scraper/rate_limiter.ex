# https://hexdocs.pm/gen_stage/GenStage.html 예제 코드를 참고함

defmodule BitcoinPriceScraper.RateLimiter do
  use GenStage
  alias BitcoinPriceScraper.Upbit
  alias __MODULE__.Producer

  defmodule Producer do
    defstruct [:limits_per_second, :pending]

    def new(limits_per_second) do
      %__MODULE__{
        limits_per_second: limits_per_second,
        # candle 조회에 실패한 이벤트를 담아두고 다음에 시도한다
        pending: []
      }
    end
  end

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
      |> Map.put(from, Producer.new(limits_per_second))
      |> ask_and_schedule(from)

    # :manual을 리턴해 생산자(producer)에 요구(demand)를 보내는 걸 직접 컨트롤한다.
    {:manual, producers}
  end

  def handle_events(events, from, producers) do
    IO.puts("handle_events - #{to_string(NaiveDateTime.utc_now())}, count: #{Enum.count(events)}")

    if not Enum.empty?(producers[from].pending) do
      IO.puts(
        "retry count: #{Enum.count(producers[from].pending)}, detail: #{
          inspect(producers[from].pending)
        }"
      )
    end

    # 이전에 실패한 candle 조회 요청을 보낸다
    {_success, pending} = request_candles(producers[from].pending)
    {_success, failed} = request_candles(events)

    producers =
      Map.update!(producers, from, fn exist ->
        # 이전에 실패한 candle 조회 요청 중 실패한 요청과
        # producer로 부터 받은 이벤트 중 실패한 목록을 업데이트해서
        # 다음에 시도할 수 있게 한다.
        %{exist | pending: pending ++ failed}
      end)

    {:noreply, [], producers}
  end

  def handle_info({:ask, from}, producers) do
    {:noreply, [], ask_and_schedule(producers, from)}
  end

  defp request_candles(events) do
    events
    |> Enum.split_with(fn e ->
      case Upbit.candles("KRW-BTC", e, 200) do
        {:ok, %{body: body, status: status, headers: headers}} ->
          remaining_req =
            Enum.find_value(headers, fn h ->
              case h do
                {"remaining-req", remain} -> remain
                _ -> nil
              end
            end)

          IO.puts(
            "status: #{status}, candle count: #{Enum.count(body)}, remaining-req: #{remaining_req}"
          )

          true

        error ->
          IO.inspect(error)
          false
      end
    end)
  end

  defp ask_and_schedule(producers, from) do
    case producers do
      %{^from => %{limits_per_second: limits_per_second, pending: pending}} ->
        # 이벤트를 요구한다. :manual 모드일 때는 GenStage.ask/2 함수를 호출해서 직접 요구해야 한다
        # 실패해서 다음에 시도해야 할 이벤트 개수를 초당 요청 가능한 개수에서 뺀 만큼 요청한다
        # 단, 0이면 handle_events 함수 호출이 안 되므로 최소 1개를 요청한다
        GenStage.ask(from, max(limits_per_second - Enum.count(pending), 1))
        # 초당 호출 개수 제한이 있으므로 1초 스케쥴링을 한다
        Process.send_after(self(), {:ask, from}, :timer.seconds(1))
        producers

      %{} ->
        producers
    end
  end
end
