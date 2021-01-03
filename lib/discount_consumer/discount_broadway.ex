defmodule DiscountBroadway do
  use Broadway

  alias Broadway.Message
  alias DiscountConsumer.Products

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          BroadwayKafka.Producer,
          [
            hosts: [localhost: 9092],
            group_id: "discount_consumers",
            topics: ["ofertas"]
          ]
        },
        concurrency: 10
      ],
      processors: [
        default: [
          concurrency: 2
        ]
      ],
      batchers: [
        big_discount: [concurrency: 2, batch_size: 10],
        discount: [concurrency: 1, batch_size: 10]
      ]
    )
  end

  def handle_message(_processor, %Message{data: data} = message, _context) do
    payload =
      data
      |> Jason.decode!()

    message =
      Message.update_data(
        message,
        &(&1 |> Jason.decode!())
      )

    if payload["discount"] >= 50 do
      Message.put_batcher(message, :big_discount)
    else
      Message.put_batcher(message, :discount)
    end
  end

  def handle_batch(:big_discount, messages, _batch_info, _context) do
    messages
    |> Enum.map(&(&1.data |> Products.create_product()))

    messages
  end

  def handle_batch(:discount, messages, _batch_info, _context) do
    messages
    |> Enum.map(&(&1.data |> Products.create_product()))

    messages
  end
end
