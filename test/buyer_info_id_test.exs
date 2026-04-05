defmodule InvoiceCake.BuyerInfo.IDTest do
  use ExUnit.Case

  alias InvoiceCake.BuyerInfo

  @country "ID"

  describe "ID personal invoice" do
    test "valid personal invoice" do
      buyer = %{
        "is_personal" => true,
        "name" => "Budi Santoso",
        "address" => "Jl. Sudirman No. 1, Jakarta",
        "email" => "budi@example.com"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer, @country)
      assert validated["name"] == "Budi Santoso"
      assert validated["address"] == "Jl. Sudirman No. 1, Jakarta"
      assert validated["email"] == "budi@example.com"
    end

    test "valid personal invoice with all fields" do
      buyer = %{
        "is_personal" => true,
        "name" => "Budi Santoso",
        "address" => "Jl. Sudirman No. 1, Jakarta",
        "email" => "budi@example.com",
        "phone_number" => "+6281234567890"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer, @country)
      assert validated["email"] == "budi@example.com"
      assert validated["phone_number"] == "+6281234567890"
    end

    test "requires name" do
      buyer = %{"is_personal" => true, "address" => "Jl. Sudirman No. 1"}
      assert {:error, "name is required"} = BuyerInfo.validate(buyer, @country)
    end

    test "requires address" do
      buyer = %{"is_personal" => true, "name" => "Budi"}
      assert {:error, "address is required"} = BuyerInfo.validate(buyer, @country)
    end

    test "validates email format" do
      buyer = %{
        "is_personal" => true,
        "name" => "Budi",
        "address" => "Jakarta",
        "email" => "not-an-email"
      }

      assert {:error, "email is invalid, regex: " <> _} = BuyerInfo.validate(buyer, @country)
    end

    test "validates phone_number format" do
      buyer = %{
        "is_personal" => true,
        "name" => "Budi",
        "address" => "Jakarta",
        "phone_number" => "12345"
      }

      assert {:error, "phone_number is invalid, regex: " <> _} =
               BuyerInfo.validate(buyer, @country)
    end

    test "accepts phone with +62 prefix" do
      buyer = %{
        "is_personal" => true,
        "name" => "Budi",
        "address" => "Jakarta",
        "phone_number" => "+6281234567890"
      }

      assert {:ok, _} = BuyerInfo.validate(buyer, @country)
    end

    test "accepts phone with 62 prefix" do
      buyer = %{
        "is_personal" => true,
        "name" => "Budi",
        "address" => "Jakarta",
        "phone_number" => "6281234567890"
      }

      assert {:ok, _} = BuyerInfo.validate(buyer, @country)
    end

    test "accepts phone with 0 prefix" do
      buyer = %{
        "is_personal" => true,
        "name" => "Budi",
        "address" => "Jakarta",
        "phone_number" => "081234567890"
      }

      assert {:ok, _} = BuyerInfo.validate(buyer, @country)
    end

    test "requires phone_number or email when both absent" do
      buyer = %{"is_personal" => true, "name" => "Budi", "address" => "Jakarta"}

      assert {:error, "phone_number or email is required"} = BuyerInfo.validate(buyer, @country)
    end

    test "valid personal with email only (no phone_number)" do
      buyer = %{
        "is_personal" => true,
        "name" => "Budi",
        "address" => "Jakarta",
        "email" => "budi@example.com"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer, @country)
      refute Map.has_key?(validated, "phone_number")
    end

    test "strips unknown fields" do
      buyer = %{
        "is_personal" => true,
        "name" => "Budi",
        "address" => "Jakarta",
        "email" => "budi@example.com",
        "unknown" => "should be removed"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer, @country)
      refute Map.has_key?(validated, "unknown")
    end
  end

  describe "ID company invoice" do
    test "valid company invoice with pkp_status no" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "address" => "Jl. Gatot Subroto, Jakarta",
        "pkp_status" => "no"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer, @country)
      assert validated["company_name"] == "PT Maju Jaya"
      assert validated["pkp_status"] == "no"
    end

    test "valid company invoice with pkp_status yes and npwp" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "address" => "Jl. Gatot Subroto, Jakarta",
        "pkp_status" => "yes",
        "npwp" => "1234567890123456"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer, @country)
      assert validated["npwp"] == "1234567890123456"
    end

    test "accepts npwp with dot-dash format" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "address" => "Jakarta",
        "pkp_status" => "yes",
        "npwp" => "12.345.678.9-012.345"
      }

      assert {:ok, _} = BuyerInfo.validate(buyer, @country)
    end

    test "requires npwp when pkp_status is yes" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "address" => "Jakarta",
        "pkp_status" => "yes"
      }

      assert {:error, "npwp is required when pkp_status is yes"} =
               BuyerInfo.validate(buyer, @country)
    end

    test "npwp not required when pkp_status is no" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "address" => "Jakarta",
        "pkp_status" => "no"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer, @country)
      refute Map.has_key?(validated, "npwp")
    end

    test "requires company_name" do
      buyer = %{
        "is_personal" => false,
        "address" => "Jakarta",
        "pkp_status" => "no"
      }

      assert {:error, "company_name is required"} = BuyerInfo.validate(buyer, @country)
    end

    test "requires address" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "pkp_status" => "no"
      }

      assert {:error, "address is required"} = BuyerInfo.validate(buyer, @country)
    end

    test "requires pkp_status" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "address" => "Jakarta"
      }

      assert {:error, "pkp_status is required"} = BuyerInfo.validate(buyer, @country)
    end

    test "validates pkp_status value" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "address" => "Jakarta",
        "pkp_status" => "maybe"
      }

      assert {:error, "pkp_status is invalid, regex: " <> _} =
               BuyerInfo.validate(buyer, @country)
    end

    test "validates npwp format" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "address" => "Jakarta",
        "pkp_status" => "yes",
        "npwp" => "invalid"
      }

      assert {:error, "npwp is invalid, regex: " <> _} = BuyerInfo.validate(buyer, @country)
    end

    test "validates email format" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "address" => "Jakarta",
        "pkp_status" => "no",
        "email" => "bad"
      }

      assert {:error, "email is invalid, regex: " <> _} = BuyerInfo.validate(buyer, @country)
    end

    test "validates phone_number format" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "address" => "Jakarta",
        "pkp_status" => "no",
        "phone_number" => "12345"
      }

      assert {:error, "phone_number is invalid, regex: " <> _} =
               BuyerInfo.validate(buyer, @country)
    end

    test "valid company invoice with all fields" do
      buyer = %{
        "is_personal" => false,
        "company_name" => "PT Maju Jaya",
        "address" => "Jl. Gatot Subroto, Jakarta",
        "pkp_status" => "yes",
        "npwp" => "1234567890123456",
        "email" => "info@majujaya.co.id",
        "phone_number" => "+6281234567890"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer, @country)
      assert validated["email"] == "info@majujaya.co.id"
      assert validated["phone_number"] == "+6281234567890"
    end
  end

  describe "ID edge cases" do
    test "raises on atom keys" do
      assert_raise ArgumentError, ~r/expected map with string keys/, fn ->
        BuyerInfo.validate(%{is_personal: true}, @country)
      end
    end

    test "empty string treated as missing for required fields" do
      buyer = %{"is_personal" => true, "name" => "", "address" => "Jakarta"}
      assert {:error, "name is required"} = BuyerInfo.validate(buyer, @country)
    end

    test "strips empty optional fields from result" do
      buyer = %{
        "is_personal" => true,
        "name" => "Budi",
        "address" => "Jakarta",
        "email" => "",
        "phone_number" => "+6281234567890"
      }

      assert {:ok, validated} = BuyerInfo.validate(buyer, @country)
      refute Map.has_key?(validated, "email")
      assert validated["phone_number"] == "+6281234567890"
    end
  end
end
