defmodule Panpipe.PandocTest do
  use ExUnit.Case
  doctest Panpipe.Pandoc

  alias Panpipe.Pandoc

  @example_doc "test/fixtures/example_doc.md"

  describe "call" do
    test "enabling extensions" do
      assert Pandoc.call(":smile:", from: {:markdown, [:emoji]}, to: :markdown) ==
               {:ok, "😄\n"}
      assert Pandoc.call(":smile:", from: {:markdown, %{enable: [:emoji]}}, to: :markdown) ==
               {:ok, "😄\n"}
    end

    test "disabling extensions" do
      assert Pandoc.call("--", to: {:markdown, %{disable: [:smart]}}) ==
               {:ok, "–\n"}
    end
  end

  describe "ast/2" do
    test "with the input in the options" do
      assert {:ok, %{"blocks" => _}} = Pandoc.ast(input: @example_doc)
    end

    test "with input string" do
      assert {:ok, %{"blocks" => _}} = Pandoc.ast("# Test")
    end

    test "with input string and options" do
      assert {:ok, %{"blocks" => [%{"c" => _}]}} = Pandoc.ast("# Test", base_header_level: 3)
    end
  end
end
