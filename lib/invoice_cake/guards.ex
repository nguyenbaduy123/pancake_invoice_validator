defmodule InvoiceCake.Guards do
  @moduledoc false
  defguard is_empty(value) when is_nil(value) or value == ""
end
