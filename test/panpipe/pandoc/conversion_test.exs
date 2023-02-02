defmodule Panpipe.Pandoc.ConversionTest do
  use ExUnit.Case

  test "AST.Plain" do
    plain = %Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "Example"}]}
    assert Panpipe.Pandoc.Conversion.convert(plain, to: :markdown) == "Example\n"
    assert Panpipe.Pandoc.Conversion.convert(plain, to: :plain) == "Example\n"
    assert Panpipe.Pandoc.Conversion.convert(plain, to: :plain, remove_trailing_newline: true) == "Example"
  end

  test "AST.Header" do
    header = %Panpipe.AST.Header{level: 1, children: [%Panpipe.AST.Str{string: "Example"}]}
    assert Panpipe.Pandoc.Conversion.convert(header, to: :markdown) == "# Example\n"
    assert Panpipe.Pandoc.Conversion.convert(header, to: :markdown, markdown_headings: "atx") == "# Example\n"
    assert Panpipe.Pandoc.Conversion.convert(header, to: :markdown, markdown_headings: "setext") == "Example\n=======\n"
    assert Panpipe.Pandoc.Conversion.convert(header, to: :plain) == "Example\n"
    assert Panpipe.Pandoc.Conversion.convert(header, to: {:plain, [:gutenberg]}) == "\n\nEXAMPLE\n"
  end

  test "AST.Para" do
    para = %Panpipe.AST.Para{children: [%Panpipe.AST.Str{string: "Example"}]}
    assert Panpipe.Pandoc.Conversion.convert(para, to: :markdown) == "Example\n"
    assert Panpipe.Pandoc.Conversion.convert(para, to: :plain) == "Example\n"
  end

  test "AST.CodeBlock" do
    code_block =
      %Panpipe.AST.CodeBlock{
        string: "Example",
      }
    assert Panpipe.Pandoc.Conversion.convert(code_block, to: :markdown) == "    Example\n"
    assert Panpipe.Pandoc.Conversion.convert(code_block, to: :plain) == "    Example\n"

    code_block =
      %Panpipe.AST.CodeBlock{
        string: "Example",
        children: [],
        attr: %Panpipe.AST.Attr{classes: ["sh"]}
      }
    assert Panpipe.Pandoc.Conversion.convert(code_block, to: {:markdown, %{disable: [:fenced_code_attributes]}}) ==
             """
             ``` sh
             Example
             ```
             """
    assert Panpipe.Pandoc.Conversion.convert(code_block, to: :plain) == "    Example\n"
  end

  test "AST.BlockQuote" do
    block_quote =
      %Panpipe.AST.BlockQuote{
        children: [
          %Panpipe.AST.Para{children: [%Panpipe.AST.Str{string: "Example"}]}
        ]
      }
    assert Panpipe.Pandoc.Conversion.convert(block_quote, to: :markdown) == "> Example\n"
    assert Panpipe.Pandoc.Conversion.convert(block_quote, to: :plain) == "  Example\n"
  end

  test "AST.OrderedList" do
    ordered_list =
      %Panpipe.AST.OrderedList{
        list_attributes: %Panpipe.AST.ListAttributes{start: 1, number_style: "Decimal", number_delimiter: "Period"},
        children: [
          %Panpipe.AST.ListElement{children: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "Example1"}]}]},
          %Panpipe.AST.ListElement{children: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "Example2"}]}]},
        ]
      }
    assert Panpipe.Pandoc.Conversion.convert(ordered_list, to: :markdown) == "1.  Example1\n2.  Example2\n"
    assert Panpipe.Pandoc.Conversion.convert(ordered_list, to: :plain) == "1.  Example1\n2.  Example2\n"
  end

  test "AST.BulletList" do
    bullet_list =
      %Panpipe.AST.BulletList{
        children: [
          %Panpipe.AST.ListElement{children: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "Example1"}]}]},
          %Panpipe.AST.ListElement{children: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "Example2"}]}]},
        ]
      }
    # Pandoc adds three spaces after the bullets; see https://github.com/jgm/pandoc/issues/3981
    assert Panpipe.Pandoc.Conversion.convert(bullet_list, to: :markdown) == "-   Example1\n-   Example2\n"
    assert Panpipe.Pandoc.Conversion.convert(bullet_list, to: :plain) == "-   Example1\n-   Example2\n"

    assert Panpipe.Pandoc.Conversion.convert(bullet_list, to: :markdown, tab_stop: 2) == "- Example1\n- Example2\n"
    assert Panpipe.Pandoc.Conversion.convert(bullet_list, to: :plain, tab_stop: 2) == "- Example1\n- Example2\n"
  end

  test "AST.DefinitionList" do
    bullet_list =
      %Panpipe.AST.DefinitionList{
        children: [
          [
            [%Panpipe.AST.Str{string: "Term"}],
            [
              [%Panpipe.AST.Para{children: [%Panpipe.AST.Str{string: "Definition"}]}]
            ]
          ]
        ]
      }
    assert Panpipe.Pandoc.Conversion.convert(bullet_list, to: :markdown) == "Term\n\n:   Definition\n"
    assert Panpipe.Pandoc.Conversion.convert(bullet_list, to: :plain) == "Term\n\n    Definition\n"
  end

  test "AST.Table" do
    table =
      %Panpipe.AST.Table{
        caption: %Panpipe.AST.Caption{
          blocks: [
            %Panpipe.AST.Plain{
              children: [
                %Panpipe.AST.Str{string: "Example"},
                %Panpipe.AST.Space{},
                %Panpipe.AST.Str{string: "table"},
                %Panpipe.AST.Space{},
                %Panpipe.AST.Str{string: "1"}
              ]
            }
          ]
        },
        col_spec: [
          %Panpipe.AST.ColSpec{alignment: "AlignLeft", col_width: "ColWidthDefault"},
          %Panpipe.AST.ColSpec{alignment: "AlignLeft", col_width: "ColWidthDefault"}
        ],
        table_head: %Panpipe.AST.TableHead{
          rows: [
            %Panpipe.AST.Row{
              cells: [
                %Panpipe.AST.Cell{
                  blocks: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "Column1"}]}],
                },
                %Panpipe.AST.Cell{
                  blocks: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "Column2"}]}],
                }
              ]
            }
          ]
        },
        table_bodies: [
          %Panpipe.AST.TableBody{
            attr: %Panpipe.AST.Attr{},
            intermediate_body_rows: [
              %Panpipe.AST.Row{
                cells: [
                  %Panpipe.AST.Cell{
                    blocks: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "cell11"}]}]
                  },
                  %Panpipe.AST.Cell{
                    blocks: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "cell12"}]}]
                  }
                ]
              },
              %Panpipe.AST.Row{
                cells: [
                  %Panpipe.AST.Cell{
                    blocks: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "cell21"}]}]
                  },
                  %Panpipe.AST.Cell{
                    blocks: [%Panpipe.AST.Plain{children: [%Panpipe.AST.Str{string: "cell22"}]}]
                  }
                ]
              }
            ]
          }
        ]
      }

    assert Panpipe.Pandoc.Conversion.convert(table, to: :markdown) == """
              Column1   Column2
              --------- ---------
              cell11    cell12
              cell21    cell22

              : Example table 1
            """
    assert Panpipe.Pandoc.Conversion.convert(table, to: :plain) == """
              Column1   Column2
              --------- ---------
              cell11    cell12
              cell21    cell22

              : Example table 1
            """
  end

  test "AST.Str" do
    str = %Panpipe.AST.Str{string: "Example"}
    assert Panpipe.Pandoc.Conversion.convert(str, to: :markdown) == "Example"
    assert Panpipe.Pandoc.Conversion.convert(str, to: :plain) == "Example"
  end

  test "AST.Emph" do
    emph = %Panpipe.AST.Emph{children: %Panpipe.AST.Str{string: "Example"}}
    assert Panpipe.Pandoc.Conversion.convert(emph, to: :markdown) == "*Example*"
    assert Panpipe.Pandoc.Conversion.convert(emph, to: :plain) == "Example"
    assert Panpipe.Pandoc.Conversion.convert(emph, to: {:plain, [:gutenberg]}) == "_Example_"
  end

  test "AST.Underline" do
    underline = %Panpipe.AST.Underline{children: %Panpipe.AST.Str{string: "Example"}}
    assert Panpipe.Pandoc.Conversion.convert(underline, to: :markdown) == "[Example]{.underline}"
    assert Panpipe.Pandoc.Conversion.convert(underline, to: :textile) == "+Example+"
    assert Panpipe.Pandoc.Conversion.convert(underline, to: :plain) == "Example"
  end

  test "AST.Strong" do
    strong = %Panpipe.AST.Strong{children: %Panpipe.AST.Str{string: "Example"}}
    assert Panpipe.Pandoc.Conversion.convert(strong, to: :markdown) == "**Example**"
    assert Panpipe.Pandoc.Conversion.convert(strong, to: :plain) == "Example"
    assert Panpipe.Pandoc.Conversion.convert(strong, to: {:plain, [:gutenberg]}) == "EXAMPLE"
  end

  test "AST.Strikeout" do
    strikeout = %Panpipe.AST.Strikeout{children: %Panpipe.AST.Str{string: "Example"}}
    assert Panpipe.Pandoc.Conversion.convert(strikeout, to: :markdown) == "~~Example~~"
    assert Panpipe.Pandoc.Conversion.convert(strikeout, to: :plain) == "~~Example~~"
  end

  test "AST.Superscript" do
    superscript = %Panpipe.AST.Superscript{children: %Panpipe.AST.Str{string: "Example"}}
    assert Panpipe.Pandoc.Conversion.convert(superscript, to: :markdown) == "^Example^"
    assert Panpipe.Pandoc.Conversion.convert(superscript, to: :plain) == "^(Example)"
  end

  test "AST.Quoted" do
    quoted = %Panpipe.AST.Quoted{children: %Panpipe.AST.Str{string: "Example"}, type: "SingleQuote"}
    assert Panpipe.Pandoc.Conversion.convert(quoted, to: :markdown) == "'Example'"
    assert Panpipe.Pandoc.Conversion.convert(quoted, to: :plain) == "‘Example’"
  end

  test "AST.Cite" do
    cite = %Panpipe.AST.Cite{children: %Panpipe.AST.Str{string: "[@Example]"},
      citations: [
        %Panpipe.AST.Cite.Citation{
          id: "Example",
          prefix: [],
          suffix: [%Panpipe.AST.Str{string: "Prefix"}],
          mode: "NormalCitation",
          note_num: 0,
          hash: 0,
        }
      ]
    }
    assert Panpipe.Pandoc.Conversion.convert(cite, to: :markdown) == "[@Example Prefix]"
    assert Panpipe.Pandoc.Conversion.convert(cite, to: :plain) == "[@Example]"
  end

  test "AST.Code" do
    code = %Panpipe.AST.Code{string: "Example"}
    assert Panpipe.Pandoc.Conversion.convert(code, to: :markdown) == "`Example`"
    assert Panpipe.Pandoc.Conversion.convert(code, to: :plain) == "Example"
  end

  test "AST.Math" do
    math = %Panpipe.AST.Math{type: "InlineMath", string: "\\pi"}
    assert Panpipe.Pandoc.Conversion.convert(math, to: :markdown) == "$\\pi$"
    assert Panpipe.Pandoc.Conversion.convert(math, to: :plain) == "π"
  end

  test "AST.RawInline" do
    raw_inline = %Panpipe.AST.RawInline{format: "html", string: "<em>"}
    assert Panpipe.Pandoc.Conversion.convert(raw_inline, to: :markdown) == "`<em>`{=html}"
    assert Panpipe.Pandoc.Conversion.convert(raw_inline, to: {:markdown, %{disable: [:raw_attribute]}}) == "<em>"
    assert Panpipe.Pandoc.Conversion.convert(raw_inline, to: :plain) == ""
  end

  test "AST.Link" do
    link = %Panpipe.AST.Link{
      children: %Panpipe.AST.Str{string: "Example"},
      target: "http://example.com"
    }
    assert Panpipe.Pandoc.Conversion.convert(link, to: :markdown) == "[Example](http://example.com)"
    assert Panpipe.Pandoc.Conversion.convert(link, to: :plain) == "Example"

    link = %Panpipe.AST.Link{
      children: %Panpipe.AST.Str{string: "http://example.com"},
      target: "http://example.com"
    }
    assert Panpipe.Pandoc.Conversion.convert(link, to: :markdown) == "<http://example.com>"
    assert Panpipe.Pandoc.Conversion.convert(link, to: :plain) == "http://example.com"
  end

  test "AST.Image" do
    image = %Panpipe.AST.Image{
      children: %Panpipe.AST.Str{string: "Example"},
      target: "http://example.com"
    }
    assert Panpipe.Pandoc.Conversion.convert(image, to: :markdown) == "![Example](http://example.com)"
    assert Panpipe.Pandoc.Conversion.convert(image, to: :plain) == "[Example]"
  end

  test "AST.Note" do
    note = %Panpipe.AST.Note{
      children: [
        %Panpipe.AST.Para{children: [%Panpipe.AST.Str{string: "Note"}]}
      ]
    }

    assert Panpipe.Pandoc.Conversion.convert(note, to: :markdown) == "[^1]\n\n[^1]: Note"
    assert Panpipe.Pandoc.Conversion.convert(note, to: :plain) == "[1]\n\n[1] Note"
  end

  test "AST.Span" do
    span = %Panpipe.AST.Span{children: [%Panpipe.AST.Str{string: "Example"}]}
    assert Panpipe.Pandoc.Conversion.convert(span, to: :markdown) == "Example"
    assert Panpipe.Pandoc.Conversion.convert(span, to: :plain) == "Example"
  end

  test "AST.Null" do
    null = %Panpipe.AST.Null{}
    assert Panpipe.Pandoc.Conversion.convert(null, to: :markdown) == "\n"
    assert Panpipe.Pandoc.Conversion.convert(null, to: :plain) == "\n"
  end
end
