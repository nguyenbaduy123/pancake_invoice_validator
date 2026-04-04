defmodule InvoiceCake.BuyerInfo.Base do
  alias InvoiceCake.BuyerInfo.Field

  defmacro __using__(_opts) do
    quote do
      @moduledoc false
      import InvoiceCake.BuyerInfo.Base, only: [personal: 1, company: 1, field: 2, field: 3]
      import InvoiceCake.Guards, only: [is_empty: 1]

      Module.register_attribute(__MODULE__, :personal_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :company_fields, accumulate: true)
      @current_target nil

      @before_compile InvoiceCake.BuyerInfo.Base
    end
  end

  defmacro personal(do: block) do
    quote do
      @current_target :personal
      unquote(block)
      @current_target nil
    end
  end

  defmacro company(do: block) do
    quote do
      @current_target :company
      unquote(block)
      @current_target nil
    end
  end

  defmacro field(name, _type, opts \\ []) do
    quote do
      @current_target || raise("field/3 must be called inside a `personal` or `company` block")

      Module.put_attribute(
        __MODULE__,
        :"#{@current_target}_fields",
        {unquote(name), unquote(opts)}
      )
    end
  end

  defmacro __before_compile__(env) do
    personal =
      env.module |> Module.get_attribute(:personal_fields) |> Enum.reverse() |> Macro.escape()

    company =
      env.module |> Module.get_attribute(:company_fields) |> Enum.reverse() |> Macro.escape()

    quote do
      def validate(buyer_info) when is_map(buyer_info) do
        if atom = Enum.find(buyer_info, fn {key, _} -> is_atom(key) end),
          do: raise(ArgumentError, "expected map with string keys, got atom key: #{inspect(atom)}"),
          else: do_validate(buyer_info)
      end

      def validate(buyer_info),
        do: raise(ArgumentError, "expected map, got #{inspect(buyer_info)}")

      defp do_validate(%{"is_personal" => is_personal} = buyer_info) do
        fields = if is_personal, do: unquote(personal), else: unquote(company)

        Enum.reduce_while(fields, %{}, fn {name, opts}, acc ->
          case Field.validate(buyer_info[name], name, opts) do
            :ok -> {:cont, Map.put(acc, name, buyer_info[name])}
            error -> {:halt, error}
          end
        end)
        |> case do
          {:error, _} = error -> error
          validated -> {:ok, Field.reject_empty_fields(validated)}
        end
      end

      defp do_validate(%{"is_personal" => value}),
        do: raise(ArgumentError, "expected `is_personal` as boolean, got #{inspect(value)}")

      defp do_validate(_),
        do: raise(ArgumentError, "expected `is_personal` field")
    end
  end
end
