defmodule InvoiceCake.ProductInfo do
  import InvoiceCake.Guards, only: [is_empty: 1]
  @item_fields ["name", "unit_name", "code", "quantity", "unit_price", "total_amount_without_tax"]
  @required_fields ["name", "total_amount_without_tax"]

  def validate(product_info) when is_list(product_info) do
    Enum.reduce_while(product_info, {:ok, []}, fn item, {:ok, acc} ->
      case validate_item(item) do
        {:ok, validated_item} ->
          {:cont, {:ok, [validated_item | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, products} -> {:ok, Enum.reverse(products)}
      error -> error
    end
  end

  def validate(_item_info), do: {:ok, nil}

  defp validate_item(item) when is_map(item) do
    missing_fields = Enum.filter(@required_fields, &is_empty(item[&1]))

    cond do
      length(missing_fields) > 0 ->
        {:error, "Missing required fields in item: #{Enum.join(missing_fields, ", ")}"}

      item["quantity"] && !is_number(item["quantity"]) ->
        {:error, "quantity must be a number"}

      item["unit_price"] && !is_number(item["unit_price"]) ->
        {:error, "unit_price must be a number"}

      item["unit_price"] && !item["quantity"] ->
        {:error, "unit_price must come with quantity"}

      !is_number(item["total_amount_without_tax"]) ->
        {:error, "total_amount_without_tax must be a number"}

      true ->
        validated_item =
          Map.take(item, @item_fields) |> Map.put_new("code", "PANCAKE_SUBSCRIPTION")

        {:ok, validated_item}
    end
  end

  defp validate_item(_item), do: {:error, "Item must be a map"}
end
