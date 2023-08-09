defmodule PanpipeTest do
  use ExUnit.Case
  doctest Panpipe

  test "wiki links" do
    assert Panpipe.ast_fragment!("[[Foo]]", from: {:markdown, [:wikilinks_title_after_pipe]}) ==
             %Panpipe.AST.Link{
               children: [%Panpipe.AST.Str{string: "Foo"}],
               target: "Foo",
               title: "wikilink"
             }

    assert Panpipe.ast_fragment!("[[Foo|title]]", from: {:markdown, [:wikilinks_title_after_pipe]}) ==
             %Panpipe.AST.Link{
               children: [%Panpipe.AST.Str{string: "title"}],
               target: "Foo",
               title: "wikilink"
             }
  end
end
