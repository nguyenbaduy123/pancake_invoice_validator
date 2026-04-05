defmodule InvoiceCake.BuyerInfo.Country.ID do
  use InvoiceCake.BuyerInfo.Base

  @regex_npwp ~r/^(\d{16}|\d{2}\.\d{3}\.\d{3}\.\d{1}-\d{3}\.\d{3})$/
  @regex_email ~r/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
  @regex_phone_number ~r/^(?:\+62|62|0)8[1-9][0-9]{7,10}$/

  personal do
    field("name", :string, required: true)
    field("address", :string, required: true)
    field("email", :string, regex: @regex_email)
    field("phone_number", :string, regex: @regex_phone_number)
  end

  company do
    field("company_name", :string, required: true)
    field("address", :string, required: true)
    field("pkp_status", :string, required: true, regex: ~r/^(yes|no)$/)
    field("npwp", :string, regex: @regex_npwp)
    field("email", :string, regex: @regex_email)
    field("phone_number", :string, regex: @regex_phone_number)
  end

  defp cross_validate(:personal, validated)
       when not is_map_key(validated, "phone_number") and not is_map_key(validated, "email"),
       do: {:error, "phone_number or email is required"}

  defp cross_validate(:company, %{"pkp_status" => "yes"} = validated) do
    if !Map.get(validated, "npwp"),
      do: {:error, "npwp is required when pkp_status is yes"},
      else: {:ok, validated}
  end
end
