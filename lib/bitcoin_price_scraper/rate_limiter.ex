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

    :telemetry.execute([:upbit, :quotation, :request, :new], %{count: Enum.count(events)})
    {_success, failed} = request_candles(events)

    producers =
      Map.update!(producers, from, fn exist ->
        # 이 함수에서는 새로운 요청을 처리할 뿐, 이전에 실패한 요청을 처리하지 않는다.
        # 실패한 요청을 다음에 시도할 수 있게 추가한다
        %{exist | pending: exist.pending ++ failed}
      end)

    {:noreply, [], producers}
  end

  def handle_info({:ask, from}, producers) do
    {:noreply, [], ask_and_schedule(producers, from)}
  end

  def handle_info({:retry, from}, producers) do
    {:noreply, [], retry_events(producers, from)}
  end

  defp request_candles(events) do
    events
    |> Enum.split_with(fn e ->
      before_request = System.monotonic_time()

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

          :telemetry.execute([:upbit, :quotation, :response, :success], %{count: 1})

          :telemetry.execute(
            [:upbit, :quotation, :request, :success, :duration, :milliseconds],
            %{duration: System.monotonic_time() - before_request}
          )

          true

        error ->
          IO.inspect(error)
          :telemetry.execute([:upbit, :quotation, :response, :failed], %{count: 1})

          :telemetry.execute(
            [:upbit, :quotation, :request, :failed, :duration, :milliseconds],
            %{duration: System.monotonic_time() - before_request}
          )

          false
      end
    end)
  end

  defp ask_and_schedule(producers, from) do
    case producers do
      %{^from => %{limits_per_second: limits_per_second, pending: pending}} ->
        GenStage.ask(from, max(limits_per_second - Enum.count(pending), 0))
        # 초당 호출 개수 제한이 있으므로 1초 스케쥴링을 한다
        Process.send_after(self(), {:ask, from}, :timer.seconds(1))

        if pending > 0 do
          Process.send_after(self(), {:retry, from}, :timer.seconds(1))
        end

        producers

      %{} ->
        producers
    end
  end

  defp retry_events(producers, from) do
    if not Enum.empty?(producers[from].pending) do
      IO.puts(
        "retry count: #{Enum.count(producers[from].pending)}, detail: #{
          inspect(producers[from].pending)
        }"
      )

      # 이전에 실패한 candle 조회 요청을 보낸다
      :telemetry.execute(
        [:upbit, :quotation, :request, :retry],
        %{count: Enum.count(producers[from].pending)}
      )

      {_success, pending} = request_candles(producers[from].pending)

      producers =
        Map.update!(producers, from, fn exist ->
          %{exist | pending: pending}
        end)

      producers
    else
      producers
    end
  end
end
