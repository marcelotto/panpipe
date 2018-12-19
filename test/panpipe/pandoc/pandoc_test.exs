defmodule Panpipe.PandocTest do
  use ExUnit.Case
  doctest Panpipe.Pandoc

  alias Panpipe.Pandoc

  @example_doc "test/fixtures/example_doc.md"


  test "ast/1" do
    assert {:ok, %{"blocks" => _}} = Pandoc.ast(input: @example_doc)
  end

end
