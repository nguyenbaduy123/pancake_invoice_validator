defmodule InvoiceCake.BuyerInfo do
  @default_country "VN"

  @supported_countries [
    "VN"
  ]

  alias InvoiceCake.BuyerInfo.Country

  for country <- @supported_countries do
    def for_country(unquote(country)),
      do: {:ok, :"#{Country}.#{unquote(country)}"}
  end

  def for_country(country), do: {:error, "unsupported country: #{country}"}

  def supported_countries, do: @supported_countries

  @spec validate(map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def validate(buyer_info, country \\ @default_country)

  def validate(buyer_info, country) when is_map(buyer_info) do
    case for_country(country) do
      {:ok, module} -> module.validate(buyer_info)
      {:error, _} = error -> error
    end
  end

  def validate(bad, _), do: raise(ArgumentError, "expected map, got #{inspect(bad)}")
end
