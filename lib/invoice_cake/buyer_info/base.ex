defmodule InvoiceCake.BuyerInfo.Base do
  alias InvoiceCake.BuyerInfo.Field

  defmacro __using__(_opts) do
    quote do
      @moduledoc false
      import InvoiceCake.BuyerInfo.Base,
        only: [personal: 1, company: 1, field: 2, field: 3]

      Module.register_attribute(__MODULE__, :regex_sources, accumulate: true)
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

  defmacro field(name, type, opts \\ []) do
    clean_opts = Keyword.delete(opts, :regex)
    regex = Keyword.get(opts, :regex)

    quote do
      @current_target || raise("field/3 must be called inside a `personal` or `company` block")

      Module.put_attribute(
        __MODULE__,
        :"#{@current_target}_fields",
        {unquote(name), unquote(type), unquote(clean_opts)}
      )

      if regex = unquote(regex) do
        @regex_sources {unquote(name), @current_target, Regex.source(regex)}
      end
    end
  end

  defmacro __before_compile__(env) do
    regex_defs =
      env.module
      |> Module.get_attribute(:regex_sources, [])
      |> Enum.map(fn {name, kind, source} ->
        quote bind_quoted: [source: source, kind: kind, name: name] do
          @_compiled_regex Regex.compile!(source)
          defp regex(unquote(kind), unquote(name)), do: @_compiled_regex
        end
      end)

    quote do
      def validate(buyer_info) when is_map(buyer_info) do
        if atom = Enum.find(buyer_info, fn {key, _} -> is_atom(key) end),
          do:
            raise(ArgumentError, "expected map with string keys, got atom key: #{inspect(atom)}"),
          else: do_validate(buyer_info)
      end

      def validate(buyer_info),
        do: raise(ArgumentError, "expected map, got #{inspect(buyer_info)}")

      defp cross_validate(_kind, validated), do: {:ok, validated}
      defoverridable cross_validate: 2

      defp do_validate(%{"is_personal" => is_personal} = buyer_info)
           when is_boolean(is_personal) do
        kind = if is_personal, do: :personal, else: :company
        fields = if is_personal, do: @personal_fields, else: @company_fields

        Enum.reduce_while(fields, %{}, fn {name, type, opts}, acc ->
          opts = if r = regex(kind, name), do: Keyword.put(opts, :regex, r), else: opts

          case Field.validate(name, type, buyer_info[name], opts) do
            :ok -> {:cont, Map.put(acc, name, buyer_info[name])}
            error -> {:halt, error}
          end
        end)
        |> case do
          {:error, _} = error ->
            error

          validated ->
            validated
            |> Field.reject_empty_fields()
            |> Map.put("is_personal", is_personal)
            |> (&cross_validate(kind, &1)).()
        end
      end

      defp do_validate(%{"is_personal" => value}),
        do: raise(ArgumentError, "expected `is_personal` as boolean, got #{inspect(value)}")

      defp do_validate(_),
        do: raise(ArgumentError, "expected `is_personal` field")

      unquote_splicing(regex_defs)
      defp regex(_, _), do: nil
    end
  end
end
