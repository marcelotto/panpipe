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

  test "ast/1" do
    assert {:ok, %{"blocks" => _}} = Pandoc.ast(input: @example_doc)
  end
end
