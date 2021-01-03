defmodule DiscountConsumer.Repo do
  use Ecto.Repo,
    otp_app: :discount_consumer,
    adapter: Ecto.Adapters.Postgres
end
