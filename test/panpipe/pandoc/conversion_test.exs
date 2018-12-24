defmodule Panpipe.Pandoc.ConversionTest do
  use ExUnit.Case

  test "AST.Plain" do
    plain = %Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "Example"}]}
    assert Panpipe.Pandoc.Conversion.convert(plain, to: :markdown) == "Example"
    assert Panpipe.Pandoc.Conversion.convert(plain, to: :plain) == "Example"
  end

  test "AST.Header" do
    header = %Panpipe.AST.Header{level: 1, children: [%Panpipe.AST.Str{string: "Example"}]}
    assert Panpipe.Pandoc.Conversion.convert(header, to: :markdown) == "Example\n======="
    assert Panpipe.Pandoc.Conversion.convert(header, to: :markdown, atx: true) == "# Example"
    assert Panpipe.Pandoc.Conversion.convert(header, to: :plain) == "EXAMPLE"
  end

  test "AST.Para" do
    para = %Panpipe.AST.Para{children: [%Panpipe.AST.Str{string: "Example"}]}
    assert Panpipe.Pandoc.Conversion.convert(para, to: :markdown) == "Example"
    assert Panpipe.Pandoc.Conversion.convert(para, to: :plain) == "Example"
  end

  test "AST.BulletList" do
    bullet_list =
      %Panpipe.AST.BulletList{
        children: [
          %Panpipe.AST.BulletPoint{children: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "Example1"}]}]},
          %Panpipe.AST.BulletPoint{children: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "Example2"}]}]},
        ]
      }
    # Pandoc adds three spaces after the bullets; see https://github.com/jgm/pandoc/issues/3981
    assert Panpipe.Pandoc.Conversion.convert(bullet_list, to: :markdown) == "-   Example1\n-   Example2"
    assert Panpipe.Pandoc.Conversion.convert(bullet_list, to: :plain) == "-   Example1\n-   Example2"

    assert Panpipe.Pandoc.Conversion.convert(bullet_list, to: :markdown, tab_stop: 2) == "- Example1\n- Example2"
    assert Panpipe.Pandoc.Conversion.convert(bullet_list, to: :plain, tab_stop: 2) == "- Example1\n- Example2"
  end

  test "AST.Str" do
    str = %Panpipe.AST.Str{string: "Example"}
    assert Panpipe.Pandoc.Conversion.convert(str, to: :markdown) == "Example"
    assert Panpipe.Pandoc.Conversion.convert(str, to: :plain) == "Example"
  end

  test "AST.Emph" do
    emph = %Panpipe.AST.Emph{text: %Panpipe.AST.Str{string: "Example"}}
    assert Panpipe.Pandoc.Conversion.convert(emph, to: :markdown) == "*Example*"
    assert Panpipe.Pandoc.Conversion.convert(emph, to: :plain) == "_Example_"
  end

  test "AST.Strong" do
    strong = %Panpipe.AST.Strong{text: %Panpipe.AST.Str{string: "Example"}}
    assert Panpipe.Pandoc.Conversion.convert(strong, to: :markdown) == "**Example**"
    assert Panpipe.Pandoc.Conversion.convert(strong, to: :plain) == "EXAMPLE"
  end

  test "AST.Link" do
    link = %Panpipe.AST.Link{
      text: %Panpipe.AST.Str{string: "Example"},
      target: "http://example.com"
    }
    assert Panpipe.Pandoc.Conversion.convert(link, to: :markdown) == "[Example](http://example.com)"
    assert Panpipe.Pandoc.Conversion.convert(link, to: :plain) == "Example"

    link = %Panpipe.AST.Link{
      text: %Panpipe.AST.Str{string: "http://example.com"},
      target: "http://example.com"
    }
    assert Panpipe.Pandoc.Conversion.convert(link, to: :markdown) == "<http://example.com>"
    assert Panpipe.Pandoc.Conversion.convert(link, to: :plain) == "http://example.com"
  end

end
