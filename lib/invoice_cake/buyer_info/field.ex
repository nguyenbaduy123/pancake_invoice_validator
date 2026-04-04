defmodule InvoiceCake.BuyerInfo.Field do
  import InvoiceCake.Guards, only: [is_empty: 1]

  def validate(value, name, opts) do
    required = Keyword.get(opts, :required, false)
    regex = Keyword.get(opts, :regex)

    cond do
      required and is_empty(value) ->
        {:error, "#{name} is required"}

      is_empty(value) ->
        :ok

      not is_nil(regex) and not Regex.match?(regex, value) ->
        {:error, "#{name} is invalid#{regex_hint(regex)}"}

      true ->
        :ok
    end
  end

  if Mix.env() in [:dev, :test] do
    defp regex_hint(regex), do: ", regex: #{inspect(regex)}"
  else
    defp regex_hint(_regex), do: ""
  end

  def reject_empty_fields(info) do
    Map.reject(info, fn {_key, value} -> is_empty(value) end)
  end
end
