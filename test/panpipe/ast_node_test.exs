defmodule Panpipe.Pandoc.AST.NodeTest do
  use ExUnit.Case

  describe "to_panpipe/1" do
    test "header" do
      example_header = %{
        "c" => [1, ["foo", [], []], [%{"c" => "Foo", "t" => "Str"}]],
        "t" => "Header"
      }

      assert Panpipe.Pandoc.AST.Node.to_panpipe(example_header) ==
               %Panpipe.AST.Header{
                 level: 1,
                 attr: Panpipe.AST.Attr.new |> Panpipe.AST.Attr.set_identifier("foo"),
                 children: [%Panpipe.AST.Str{string: "Foo"}]
               }
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

  describe "transform/2" do
    test "replace a node with another node" do
      assert {:ok, document} = Panpipe.ast "<http://example.com/foo>"
      assert transformed = Panpipe.Document.transform(document, fn
               %Panpipe.AST.Link{} = link ->
                 %Panpipe.AST.Link{link |
                   target: link.target <> "bar",
                   children: [%Panpipe.AST.Str{string: "http://example.com/foobar"}]
                 }

               _ -> nil
             end)

      assert transformed == Panpipe.ast! "<http://example.com/foobar>"
    end

    test "replace a node with a list of nodes" do
      assert {:ok, document} = Panpipe.ast "<http://example.com/foo>"
      assert transformed = Panpipe.Document.transform(document, fn
               %Panpipe.AST.Link{} = link ->
                 [
                   %Panpipe.AST.Str{string: "Test:"},
                   %Panpipe.AST.Space{},
                   link
                 ]
               _ -> nil
             end)

      assert transformed == Panpipe.ast! "Test: <http://example.com/foo>"
    end

    test "replace a node with an empty list" do
      assert {:ok, document} = Panpipe.ast "Test:<http://example.com/foo>"
      assert transformed = Panpipe.Document.transform(document, fn
               %Panpipe.AST.Link{} = link -> []
               _ -> nil
             end)

      assert transformed == Panpipe.ast! "Test:"
    end

    test "the transformation traversal continues on transformed paths" do
      assert {:ok, document} = Panpipe.ast("# <http://example.com/foo>",
                          from: {:markdown, %{disable: [:auto_identifiers]}})
      assert transformed = Panpipe.Document.transform(document, fn
               %Panpipe.AST.Header{} = header->
                 %Panpipe.AST.Header{header | level: header.level + 1}

               %Panpipe.AST.Link{} = link ->
                 %Panpipe.AST.Link{link |
                   target: link.target <> "bar",
                   children: [%Panpipe.AST.Str{string: "http://example.com/foobar"}]
                 }

               _ -> nil
             end)

      assert transformed == Panpipe.ast! "## <http://example.com/foobar>",
                              from: {:markdown, %{disable: [:auto_identifiers]}}

      assert transformed = Panpipe.Document.transform(document, fn
               %Panpipe.AST.Header{} = header->
                 [
                  header,
                   %Panpipe.AST.Para{children: %Panpipe.AST.Str{string: "Foo"}},
                 ]

               %Panpipe.AST.Link{} = link ->
                 %Panpipe.AST.Link{link |
                   target: link.target <> "bar",
                   children: [%Panpipe.AST.Str{string: "http://example.com/foobar"}]
                 }

               _ -> nil
             end)

      assert transformed == Panpipe.ast! "# <http://example.com/foobar>\nFoo",
                                         from: {:markdown, %{disable: [:auto_identifiers]}}
    end

    test "with a node having children in other fields" do
      assert {:ok, document} =
               Panpipe.ast """
                 Right     <http://example.com/header>
               -------     ------
                     1     <http://example.com/cell>

               Table: <http://example.com/caption>
               """
      assert transformed = Panpipe.Document.transform(document, fn
               %Panpipe.AST.Link{} = link ->
                 %Panpipe.AST.Link{link |
                   target: link.target <> "-foo",
                   children: [%Panpipe.AST.Str{string: link.target <> "-foo"}]
                 }

               _ -> nil
             end)

      assert transformed == Panpipe.ast! """
               Right     <http://example.com/header-foo>
             -------     ------
                   1     <http://example.com/cell-foo>

             Table: <http://example.com/caption-foo>
             """
    end

    test "the transformation traversal is not continued on transformed paths when applied transformation function returns a :halt tuple" do
      assert {:ok, document} = Panpipe.ast "<http://example.com/foo>"
      assert transformed = Panpipe.Document.transform(document, fn
               %Panpipe.AST.Link{} = link ->
                 {:halt,
                   %Panpipe.AST.Link{link |
                     target: link.target <> "bar",
                     children: [%Panpipe.AST.Str{string: "http://example.com/foobar"}]
                   }
                 }
               %Panpipe.AST.Str{string: "http://example.com/foobar"} ->
                 raise "This should not be reached."

               _ -> nil
             end)

      assert transformed == Panpipe.ast! "<http://example.com/foobar>"

      assert {:ok, document} = Panpipe.ast "<http://example.com/foo>"
      assert transformed = Panpipe.Document.transform(document, fn
               %Panpipe.AST.Link{} = link ->
                 [
                   %Panpipe.AST.Str{string: "Test:"},
                   %Panpipe.AST.Space{},
                   link
                 ]

               %Panpipe.AST.Str{string: "Test:"} ->
                 raise "This should not be reached."

               %Panpipe.AST.Space{} ->
                 raise "This should not be reached."

               _ -> nil
             end)

      assert transformed == Panpipe.ast! "Test: <http://example.com/foo>"
    end
  end

  [
    # blocks
    :plain,
    :header,

    # inlines
    :str,
    :emph,
    :strong,
    :link,
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
