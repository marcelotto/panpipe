defmodule Panpipe.Pandoc.AST.NodeTest do
  use ExUnit.Case

  describe "to_panpipe/1" do
    test "header" do
      example_header = %{
        "c" => [1, ["foo", [], []], [%{"c" => "Foo", "t" => "Str"}]],
        "t" => "Header"
      }

      assert Panpipe.Pandoc.AST.Node.to_panpipe(example_header) ==
               %Panpipe.AST.Header{level: 1, attr: ["foo", [], []], children: [%Panpipe.AST.Str{string: "Foo"}]}
    end
  end

end

defmodule Panpipe.AST.NodeTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Panpipe.AST.Node

  alias Panpipe.Generators, as: Gen

  @example_doc "test/fixtures/example_doc.md"


  test "Enumerable.reduce/2" do
    root = %Panpipe.AST.Header{
      level: 1,
      attr: nil,
      children: [%Panpipe.AST.Str{string: "Foo"}]
    }

    assert Enum.to_list(root) ==
            [
              root,
              %Panpipe.AST.Str{string: "Foo", parent: root}
            ]
  end

  test "Enum.filter/2" do
    {:ok, document} = Panpipe.ast(input: @example_doc)

    assert document
           |> Enum.filter(fn node -> match?(%Panpipe.AST.Link{}, node) end)
           |> Enum.map(fn link -> link.target end)
           ==
            [
              "http://example.com/foo1",
              "http://example.com/foo2",
              "http://example.com/foo3",
              "http://example.com/foo4",
            ]
  end


  [
    # blocks
    :plain,
    :header,
    # TODO: :para,
    # TODO: :bullet_list,

    # inlines
    :str,
    :emph,
    :strong,
    :link,
    # TODO: :space,
  ]
  |> Enum.each(fn node_type ->
       property "Pandoc.AST.Node.to_panpipe is inverse to Panpipe.AST.to_pandoc (#{to_string(node_type)})" do
         check all %mod{} = node <- Gen.ast_node(unquote(node_type)) do
           assert node
                  |> mod.to_pandoc()
                  |> Panpipe.Pandoc.AST.Node.to_panpipe()
                  == node
         end
       end
     end)

end
