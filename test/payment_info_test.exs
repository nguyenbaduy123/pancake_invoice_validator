defmodule InvoiceCake.PaymentInfoTest do
  use ExUnit.Case

  alias InvoiceCake.PaymentInfo

  describe "validate/1 with nil" do
    test "returns {:ok, nil}" do
      assert {:ok, nil} = PaymentInfo.validate(nil)
    end
  end

  describe "validate/1 with valid payment info" do
    test "validates complete payment info" do
      payment = %{
        "tax_percentage" => 10,
        "tax_amount" => 10_000,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 110_000
      }

      assert {:ok, validated} = PaymentInfo.validate(payment)
      assert validated["tax_percentage"] == 10
      assert validated["tax_amount"] == 10_000
      assert validated["total_amount_without_tax"] == 100_000
      assert validated["total_amount_with_tax"] == 110_000
    end

    test "adds default payment_method TM/CK" do
      payment = %{
        "tax_percentage" => 10,
        "tax_amount" => 10_000,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 110_000
      }

      assert {:ok, validated} = PaymentInfo.validate(payment)
      assert validated["payment_method"] == "TM/CK"
    end

    test "keeps provided payment_method" do
      payment = %{
        "tax_percentage" => 10,
        "tax_amount" => 10_000,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 110_000,
        "payment_method" => "CASH"
      }

      assert {:ok, validated} = PaymentInfo.validate(payment)
      assert validated["payment_method"] == "TM/CK"
    end

    test "strips unknown fields" do
      payment = %{
        "tax_percentage" => 10,
        "tax_amount" => 10_000,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 110_000,
        "unknown_field" => "should be removed"
      }

      assert {:ok, validated} = PaymentInfo.validate(payment)
      refute Map.has_key?(validated, "unknown_field")
    end
  end

  describe "validate/1 tax_percentage values" do
    test "accepts tax_percentage -2" do
      payment = %{
        "tax_percentage" => -2,
        "tax_amount" => 0,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 100_000
      }

      assert {:ok, _} = PaymentInfo.validate(payment)
    end

    test "accepts tax_percentage 0" do
      payment = %{
        "tax_percentage" => 0,
        "tax_amount" => 0,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 100_000
      }

      assert {:ok, _} = PaymentInfo.validate(payment)
    end

    test "accepts tax_percentage 5" do
      payment = %{
        "tax_percentage" => 5,
        "tax_amount" => 5_000,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 105_000
      }

      assert {:ok, _} = PaymentInfo.validate(payment)
    end

    test "accepts tax_percentage 8" do
      payment = %{
        "tax_percentage" => 8,
        "tax_amount" => 8_000,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 108_000
      }

      assert {:ok, _} = PaymentInfo.validate(payment)
    end

    test "rejects invalid tax_percentage" do
      payment = %{
        "tax_percentage" => 15,
        "tax_amount" => 15_000,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 115_000
      }

      assert {:error, "tax_percentage must be in [-2, 0, 5, 8, 10], got 15"} =
               PaymentInfo.validate(payment)
    end

    test "rejects tax_percentage 1" do
      payment = %{
        "tax_percentage" => 1,
        "tax_amount" => 1_000,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 101_000
      }

      assert {:error, "tax_percentage must be in [-2, 0, 5, 8, 10], got 1"} =
               PaymentInfo.validate(payment)
    end
  end

  describe "validate/1 missing fields" do
    test "errors when tax_percentage is missing" do
      payment = %{
        "tax_amount" => 10_000,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 110_000
      }

      assert {:error, "missing fields: " <> _} = PaymentInfo.validate(payment)
    end

    test "errors when tax_amount is missing" do
      payment = %{
        "tax_percentage" => 10,
        "total_amount_without_tax" => 100_000,
        "total_amount_with_tax" => 110_000
      }

      assert {:error, "missing fields: " <> _} = PaymentInfo.validate(payment)
    end

    test "errors when total_amount_without_tax is missing" do
      payment = %{
        "tax_percentage" => 10,
        "tax_amount" => 10_000,
        "total_amount_with_tax" => 110_000
      }

      assert {:error, "missing fields: " <> _} = PaymentInfo.validate(payment)
    end

    test "errors when total_amount_with_tax is missing" do
      payment = %{
        "tax_percentage" => 10,
        "tax_amount" => 10_000,
        "total_amount_without_tax" => 100_000
      }

      assert {:error, "missing fields: " <> _} = PaymentInfo.validate(payment)
    end

    test "errors with empty map" do
      assert {:error, "missing fields: " <> _} = PaymentInfo.validate(%{})
    end
  end
end
