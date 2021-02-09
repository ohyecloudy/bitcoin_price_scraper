defmodule BitcoinPriceScraper.Metrics.Handler do
  use Prometheus.Metric

  def start() do
    counters = [
      [:upbit, :quotation, :request, :new],
      [:upbit, :quotation, :request, :retry],
      [:upbit, :quotation, :response, :success],
      [:upbit, :quotation, :response, :failed]
    ]

    :telemetry.attach_many("upbit-counters", counters, &handle_event_counter/4, nil)

    counters
    |> Enum.each(fn name ->
      Counter.declare(
        name: counter_name(name),
        help: inspect(name)
      )
    end)

    summaries = [
      [:upbit, :quotation, :request, :success, :duration, :milliseconds],
      [:upbit, :quotation, :request, :failed, :duration, :milliseconds]
    ]

    :telemetry.attach_many("upbit-summaries", summaries, &handle_event_summary/4, nil)

    summaries
    |> Enum.each(fn name ->
      Summary.declare(
        name: name(name),
        help: inspect(name),
        duration_unit: :milliseconds
      )
    end)
  end

  def handle_event_counter(event_name, %{count: count}, _metadata, _config) do
    Counter.inc([name: counter_name(event_name)], count)
  end

  def handle_event_summary(event_name, %{duration: duration_native}, _metadata, _config) do
    Summary.observe([name: name(event_name)], duration_native)
  end

  defp counter_name(event_name) do
    :"#{name(event_name)}_total"
  end

  defp name(event_name) do
    event_name |> Enum.join("_")
  end
end
