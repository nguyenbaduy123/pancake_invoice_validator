defmodule InvoiceCake.PaymentInfo do
  @required_fields [
    "tax_percentage",
    "tax_amount",
    "total_amount_without_tax",
    "total_amount_with_tax"
  ]

  def validate(nil), do: {:ok, nil}

  def validate(payment_info) do
    payment_info
    |> Map.take(@required_fields)
    |> case do
      payment_info when map_size(payment_info) == length(@required_fields) ->
        Enum.reduce_while(payment_info, payment_info, fn {field, value}, acc ->
          case validate_field(field, value) do
            :ok -> {:cont, acc}
            {:error, message} -> {:halt, {:error, message}}
          end
        end)
        |> case do
          {:error, message} -> {:error, message}
          payment_info -> {:ok, Map.put_new(payment_info, "payment_method", "TM/CK")}
        end

      missing_fields ->
        {:error, "missing fields: #{inspect(missing_fields)}"}
    end
  end

  def validate_field("tax_percentage", tax_percentage) do
    if tax_percentage in [-2, 0, 5, 8, 10],
      do: :ok,
      else: {:error, "tax_percentage must be in [-2, 0, 5, 8, 10], got #{tax_percentage}"}
  end

  def validate_field(_, _), do: :ok
end
