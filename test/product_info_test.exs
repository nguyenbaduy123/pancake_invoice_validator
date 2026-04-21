defmodule InvoiceCake.ProductInfoTest do
  use ExUnit.Case

  alias InvoiceCake.ProductInfo

  describe "validate/1 with non-list input" do
    test "returns {:ok, nil} for nil" do
      assert {:ok, nil} = ProductInfo.validate(nil)
    end

    test "returns {:ok, nil} for a string" do
      assert {:ok, nil} = ProductInfo.validate("not a list")
    end
  end

  describe "validate/1 with valid items" do
    test "validates a single valid item" do
      items = [%{"name" => "Service A", "total_amount_without_tax" => 100_000}]
      assert {:ok, [validated]} = ProductInfo.validate(items)
      assert validated["name"] == "Service A"
      assert validated["total_amount_without_tax"] == 100_000
    end

    test "validates multiple items" do
      items = [
        %{"name" => "Item 1", "total_amount_without_tax" => 50_000},
        %{"name" => "Item 2", "total_amount_without_tax" => 75_000}
      ]

      assert {:ok, validated} = ProductInfo.validate(items)
      assert length(validated) == 2
      assert Enum.at(validated, 0)["name"] == "Item 1"
      assert Enum.at(validated, 1)["name"] == "Item 2"
    end

    test "preserves item order" do
      items = [
        %{"name" => "First", "total_amount_without_tax" => 1},
        %{"name" => "Second", "total_amount_without_tax" => 2},
        %{"name" => "Third", "total_amount_without_tax" => 3}
      ]

      assert {:ok, validated} = ProductInfo.validate(items)
      assert Enum.map(validated, & &1["name"]) == ["First", "Second", "Third"]
    end

    test "adds default code PANCAKE_SUBSCRIPTION when not provided" do
      items = [%{"name" => "Service", "total_amount_without_tax" => 100}]
      assert {:ok, [validated]} = ProductInfo.validate(items)
      assert validated["code"] == "PANCAKE_SUBSCRIPTION"
    end

    test "keeps provided code" do
      items = [%{"name" => "Service", "total_amount_without_tax" => 100, "code" => "CUSTOM"}]
      assert {:ok, [validated]} = ProductInfo.validate(items)
      assert validated["code"] == "CUSTOM"
    end

    test "validates item with all fields" do
      items = [
        %{
          "name" => "Widget",
          "unit_name" => "pcs",
          "code" => "W001",
          "quantity" => 5,
          "unit_price" => 200,
          "total_amount_without_tax" => 1000
        }
      ]

      assert {:ok, [validated]} = ProductInfo.validate(items)
      assert validated["name"] == "Widget"
      assert validated["unit_name"] == "pcs"
      assert validated["code"] == "W001"
      assert validated["quantity"] == 5
      assert validated["unit_price"] == 200
      assert validated["total_amount_without_tax"] == 1000
    end

    test "strips unknown fields" do
      items = [
        %{
          "name" => "Service",
          "total_amount_without_tax" => 100,
          "unknown_field" => "should be removed"
        }
      ]

      assert {:ok, [validated]} = ProductInfo.validate(items)
      refute Map.has_key?(validated, "unknown_field")
    end

    test "accepts float total_amount_without_tax" do
      items = [%{"name" => "Service", "total_amount_without_tax" => 99.99}]
      assert {:ok, [validated]} = ProductInfo.validate(items)
      assert validated["total_amount_without_tax"] == 99.99
    end
  end

  describe "validate/1 required fields" do
    test "requires name" do
      items = [%{"total_amount_without_tax" => 100}]
      assert {:error, "Missing required fields in item: name"} = ProductInfo.validate(items)
    end

    test "requires total_amount_without_tax" do
      items = [%{"name" => "Service"}]

      assert {:error, "Missing required fields in item: total_amount_without_tax"} =
               ProductInfo.validate(items)
    end

    test "reports all missing required fields" do
      items = [%{"unit_name" => "pcs"}]

      assert {:error, "Missing required fields in item: name, total_amount_without_tax"} =
               ProductInfo.validate(items)
    end

    test "treats nil name as missing" do
      items = [%{"name" => nil, "total_amount_without_tax" => 100}]
      assert {:error, "Missing required fields in item: name"} = ProductInfo.validate(items)
    end

    test "treats empty string name as missing" do
      items = [%{"name" => "", "total_amount_without_tax" => 100}]
      assert {:error, "Missing required fields in item: name"} = ProductInfo.validate(items)
    end
  end

  describe "validate/1 type checking" do
    test "rejects non-integer quantity" do
      items = [%{"name" => "S", "total_amount_without_tax" => 100, "quantity" => "five"}]
      assert {:error, "quantity must be a number"} = ProductInfo.validate(items)
    end

    test "accepts float quantity" do
      items = [%{"name" => "S", "total_amount_without_tax" => 100, "quantity" => 2.5}]
      assert {:ok, _} = ProductInfo.validate(items)
    end

    test "rejects non-number unit_price" do
      items = [
        %{"name" => "S", "total_amount_without_tax" => 100, "quantity" => 1, "unit_price" => "10"}
      ]

      assert {:error, "unit_price must be a number"} = ProductInfo.validate(items)
    end

    test "accepts float unit_price" do
      items = [
        %{
          "name" => "S",
          "total_amount_without_tax" => 99.9,
          "quantity" => 1,
          "unit_price" => 99.9
        }
      ]

      assert {:ok, _} = ProductInfo.validate(items)
    end

    test "rejects non-number total_amount_without_tax" do
      items = [%{"name" => "S", "total_amount_without_tax" => "100"}]
      assert {:error, "total_amount_without_tax must be a number"} = ProductInfo.validate(items)
    end
  end

  describe "validate/1 unit_price and quantity logic" do
    test "rejects unit_price without quantity" do
      items = [%{"name" => "S", "total_amount_without_tax" => 100, "unit_price" => 50}]
      assert {:error, "unit_price must come with quantity"} = ProductInfo.validate(items)
    end

    test "accepts unit_price with quantity regardless of total" do
      items = [
        %{"name" => "S", "total_amount_without_tax" => 999, "quantity" => 2, "unit_price" => 100}
      ]

      assert {:ok, _} = ProductInfo.validate(items)
    end

    test "allows quantity without unit_price" do
      items = [%{"name" => "S", "total_amount_without_tax" => 100, "quantity" => 3}]
      assert {:ok, _} = ProductInfo.validate(items)
    end

    test "accepts float unit_price with float quantity" do
      items = [
        %{
          "name" => "S",
          "total_amount_without_tax" => 49.95,
          "quantity" => 3.5,
          "unit_price" => 16.65
        }
      ]

      assert {:ok, _} = ProductInfo.validate(items)
    end
  end

  describe "validate/1 non-map items" do
    test "rejects non-map item" do
      items = ["not a map"]
      assert {:error, "Item must be a map"} = ProductInfo.validate(items)
    end

    test "stops at first invalid item" do
      items = [
        %{"name" => "Valid", "total_amount_without_tax" => 100},
        %{"unit_name" => "missing required"}
      ]

      assert {:error, "Missing required fields in item: name, total_amount_without_tax"} =
               ProductInfo.validate(items)
    end
  end

  describe "validate/1 empty list" do
    test "returns empty list for empty input" do
      assert {:ok, []} = ProductInfo.validate([])
    end
  end
end
