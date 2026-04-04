defmodule InvoiceCake.BuyerInfoTest do
  use ExUnit.Case

  alias InvoiceCake.BuyerInfo

  describe "validate/2 routing" do
    test "defaults to VN" do
      buyer = %{"is_personal" => true, "name" => "Duy", "id_number" => "079302123456"}
      assert {:ok, _} = BuyerInfo.validate(buyer)
    end

    test "returns error for unsupported country" do
      assert {:error, "unsupported country: XX"} = BuyerInfo.validate(%{}, "XX")
    end

    test "raises on nil input" do
      assert_raise ArgumentError, ~r/expected map/, fn ->
        BuyerInfo.validate(nil)
      end
    end

    test "raises on non-map input" do
      assert_raise ArgumentError, ~r/expected map/, fn ->
        BuyerInfo.validate("not a map")
      end
    end
  end

  describe "VN personal invoice" do
    test "valid personal invoice" do
      buyer = %{
        "is_personal" => true,
        "name" => "Nguyen Van A",
        "id_number" => "079302123456",
        "email" => "test@example.com",
        "address" => "123 Street"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer)
      assert validated["name"] == "Nguyen Van A"
      assert validated["id_number"] == "079302123456"
    end

    test "strips unknown fields" do
      buyer = %{
        "is_personal" => true,
        "name" => "Duy",
        "id_number" => "079302123456",
        "unknown_field" => "should be removed"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer)
      refute Map.has_key?(validated, "unknown_field")
    end

    test "requires name" do
      buyer = %{"is_personal" => true, "id_number" => "079302123456"}
      assert {:error, "name is required"} = BuyerInfo.validate(buyer)
    end

    test "requires id_number" do
      buyer = %{"is_personal" => true, "name" => "Duy"}
      assert {:error, "id_number is required"} = BuyerInfo.validate(buyer)
    end

    test "validates id_number format" do
      buyer = %{"is_personal" => true, "name" => "Duy", "id_number" => "invalid"}
      assert {:error, "id_number is invalid, regex: " <> _} = BuyerInfo.validate(buyer)
    end

    test "validates email format" do
      buyer = %{
        "is_personal" => true,
        "name" => "Duy",
        "id_number" => "079302123456",
        "email" => "not-an-email"
      }

      assert {:error, "email is invalid, regex: " <> _} = BuyerInfo.validate(buyer)
    end

    test "accepts valid semicolon-separated emails" do
      buyer = %{
        "is_personal" => true,
        "name" => "Duy",
        "id_number" => "079302123456",
        "email" => "a@b.com;c@d.com"
      }

      assert {:ok, _} = BuyerInfo.validate(buyer)
    end

    test "accepts three semicolon-separated emails" do
      buyer = %{
        "is_personal" => true,
        "name" => "Duy",
        "id_number" => "079302123456",
        "email" => "a@b.com;c@d.com;e@f.org"
      }

      assert {:ok, _} = BuyerInfo.validate(buyer)
    end

    test "rejects semicolon-separated emails with invalid entry" do
      buyer = %{
        "is_personal" => true,
        "name" => "Duy",
        "id_number" => "079302123456",
        "email" => "a@b.com;invalid;c@d.com"
      }

      assert {:error, "email is invalid, regex: " <> _} = BuyerInfo.validate(buyer)
    end

    test "rejects trailing semicolon in email" do
      buyer = %{
        "is_personal" => true,
        "name" => "Duy",
        "id_number" => "079302123456",
        "email" => "a@b.com;"
      }

      assert {:error, "email is invalid, regex: " <> _} = BuyerInfo.validate(buyer)
    end

    test "optional fields can be omitted" do
      buyer = %{"is_personal" => true, "name" => "Duy", "id_number" => "079302123456"}
      assert {:ok, _} = BuyerInfo.validate(buyer)
    end
  end

  describe "VN company invoice" do
    test "valid company invoice" do
      buyer = %{
        "is_personal" => false,
        "tax_code" => "0123456789",
        "company_name" => "ACME Corp",
        "address" => "456 Street",
        "email" => "info@acme.com"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer)
      assert validated["tax_code"] == "0123456789"
      assert validated["company_name"] == "ACME Corp"
    end

    test "requires tax_code" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "ACME",
        "address" => "456 Street"
      }

      assert {:error, "tax_code is required"} = BuyerInfo.validate(buyer)
    end

    test "validates tax_code format" do
      buyer = %{
        "is_personal" => false,
        "tax_code" => "invalid",
        "company_name" => "ACME",
        "address" => "456 Street"
      }

      assert {:error, "tax_code is invalid, regex: " <> _} = BuyerInfo.validate(buyer)
    end

    test "accepts tax_code with branch suffix" do
      buyer = %{
        "is_personal" => false,
        "tax_code" => "0123456789-001",
        "company_name" => "ACME Corp",
        "address" => "456 Street"
      }

      assert {:ok, _} = BuyerInfo.validate(buyer)
    end

    test "requires company_name" do
      buyer = %{
        "is_personal" => false,
        "tax_code" => "0123456789",
        "address" => "456 Street"
      }

      assert {:error, "company_name is required"} = BuyerInfo.validate(buyer)
    end

    test "requires address" do
      buyer = %{
        "is_personal" => false,
        "tax_code" => "0123456789",
        "company_name" => "ACME"
      }

      assert {:error, "address is required"} = BuyerInfo.validate(buyer)
    end

    test "validates email format" do
      buyer = %{
        "is_personal" => false,
        "tax_code" => "0123456789",
        "company_name" => "ACME",
        "address" => "456 Street",
        "email" => "bad"
      }

      assert {:error, "email is invalid, regex: " <> _} = BuyerInfo.validate(buyer)
    end
  end

  describe "VN type checking" do
    test "rejects non-string name" do
      buyer = %{"is_personal" => true, "name" => 123, "id_number" => "079302123456"}
      assert {:error, "invalid name type, expected string"} = BuyerInfo.validate(buyer)
    end

    test "rejects non-string id_number" do
      buyer = %{"is_personal" => true, "name" => "Duy", "id_number" => 12345}
      assert {:error, "invalid id_number type, expected string"} = BuyerInfo.validate(buyer)
    end

    test "rejects non-string email" do
      buyer = %{
        "is_personal" => true,
        "name" => "Duy",
        "id_number" => "079302123456",
        "email" => 123
      }

      assert {:error, "invalid email type, expected string"} = BuyerInfo.validate(buyer)
    end

    test "rejects non-string address" do
      buyer = %{
        "is_personal" => true,
        "name" => "Duy",
        "id_number" => "079302123456",
        "address" => 456
      }

      assert {:error, "invalid address type, expected string"} = BuyerInfo.validate(buyer)
    end

    test "rejects non-string tax_code" do
      buyer = %{
        "is_personal" => false,
        "tax_code" => 123,
        "company_name" => "ACME",
        "address" => "456 Street"
      }

      assert {:error, "invalid tax_code type, expected string"} = BuyerInfo.validate(buyer)
    end

    test "rejects non-string company_name" do
      buyer = %{
        "is_personal" => false,
        "tax_code" => "0123456789",
        "company_name" => 999,
        "address" => "456 Street"
      }

      assert {:error, "invalid company_name type, expected string"} = BuyerInfo.validate(buyer)
    end
  end

  describe "VN edge cases" do
    test "raises on atom keys" do
      assert_raise ArgumentError, ~r/expected map with string keys/, fn ->
        BuyerInfo.validate(%{is_personal: true})
      end
    end

    test "empty string treated as missing for required fields" do
      buyer = %{"is_personal" => true, "name" => "", "id_number" => "079302123456"}
      assert {:error, "name is required"} = BuyerInfo.validate(buyer)
    end

    test "strips empty optional fields from result" do
      buyer = %{
        "is_personal" => true,
        "name" => "Duy",
        "id_number" => "079302123456",
        "email" => ""
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer)
      refute Map.has_key?(validated, "email")
    end
  end
end
