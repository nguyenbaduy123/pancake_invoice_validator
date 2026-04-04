defmodule InvoiceCake.BuyerInfo.Country.VN do
  use InvoiceCake.BuyerInfo.Base

  @id_number_regex ~r/^[0-9]{3}[0-3][0-9]{2}[0-9]{6}$/
  @email_regex ~r/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(;[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})*$/
  @tax_code_regex ~r/^(\d{10}(-\d{3})?|[0-9]{3}[0-3][0-9]{2}[0-9]{6})$/

  personal do
    field("name", :string, required: true)
    field("id_number", :string, required: true, regex: @id_number_regex)
    field("email", :string, regex: @email_regex)
    field("address", :string)
  end

  company do
    field("tax_code", :string, required: true, regex: @tax_code_regex)
    field("company_name", :string, required: true)
    field("email", :string, regex: @email_regex)
    field("address", :string, required: true)
  end
end
