import ProtocolEx

defprotocol_ex Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(node)
end

################################################################################
# Helper struct: Attr

defmodule Panpipe.AST.Attr do
  defstruct [
    identifier: "",       # :: String
    classes: [],          # :: [String]
    key_value_pairs: %{}  # :: [(String, String)]
  ]

  def new(), do: %__MODULE__{}

  def set_identifier(%__MODULE__{} = attr, identifier) do
    %__MODULE__{attr | identifier: identifier}
  end

  def add_class(%__MODULE__{} = attr, class) do
    %__MODULE__{attr | classes: List.wrap(attr.classes) ++ List.wrap(class)}
  end

  def add_key_value_pairs(%__MODULE__{} = attr, key_value_pairs) when is_map(key_value_pairs)do
    %__MODULE__{attr | key_value_pairs: Map.merge(attr.key_value_pairs,
      Map.new(key_value_pairs, fn {key, value} -> {to_string(key), to_string(value)} end))
    }
  end

  def add_key_value_pairs(%__MODULE__{} = attr, key_value_pairs) when is_list(key_value_pairs)do
    add_key_value_pairs(attr, Map.new(key_value_pairs))
  end

  def from_pandoc([identifier, classes, key_value_pairs]) do
    %__MODULE__{
      identifier: identifier,
      classes: classes,
      key_value_pairs: Map.new(key_value_pairs, fn [key, value] -> {key, value} end)
    }
  end

  def to_pandoc(%__MODULE__{} = attr) do
    [
      attr.identifier,
      attr.classes,
      (attr.key_value_pairs || %{})
      |> Enum.map(fn {key, value} -> [key, value] end),
    ]
  end

  def to_pandoc(nil), do: ["", [], []]
end

################################################################################
# Plain [Inline] - Plain text, not a paragraph

defmodule Panpipe.AST.Plain do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Plain`.
  """

  use Panpipe.AST.Node, type: :block

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children}) do
    %{
      "t" => "Plain",
      "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)
    }
  end
end

defimpl_ex Panpipe.Pandoc.Plain, %{"t" => "Plain"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.Plain{
      children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1)
    }
  end
end


################################################################################
# Para [Inline] - Paragraph

defmodule Panpipe.AST.Para do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Para`.
  """

  use Panpipe.AST.Node, type: :block

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children}) do
    %{
      "t" => "Para",
      "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)
    }
  end
end

defimpl_ex Panpipe.Pandoc.Para, %{"t" => "Para"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.Para{
      children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
    }
  end
end


################################################################################
# LineBlock [[Inline]] - Multiple non-breaking lines

defmodule Panpipe.AST.LineBlock do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `LineBlock`.
  """

  use Panpipe.AST.Node, type: :block

  def child_type(), do: :inline

  # TODO: test in traversal tests, if we need to flatten the children

  def to_pandoc(%__MODULE__{children: children}) do
    %{
      "t" => "LineBlock",
      "c" => Enum.map(children, fn child ->
               Enum.map(child, &Panpipe.AST.Node.to_pandoc/1)
             end)
    }
  end
end

defimpl_ex Panpipe.Pandoc.LineBlock, %{"t" => "LineBlock"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.LineBlock{
      children: Enum.map(children, fn child ->
                  Enum.map(child, &Panpipe.Pandoc.AST.Node.to_panpipe/1)
                end)
    }
  end
end


################################################################################
# CodeBlock Attr String - Code block (literal) with attributes

defmodule Panpipe.AST.CodeBlock do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `CodeBlock`.
  """

  use Panpipe.AST.Node, type: :block, fields: [:string, attr: %Panpipe.AST.Attr{}]

  def child_type(), do: nil

  def to_pandoc(%__MODULE__{string: string, attr: attr}) do
    %{
      "t" => "CodeBlock",
      "c" => [Panpipe.AST.Attr.to_pandoc(attr), string]
    }
  end

  def language(%__MODULE__{attr: attr}),
    do: attr.classes |> List.wrap() |> List.first()
end

defimpl_ex Panpipe.Pandoc.CodeBlock, %{"t" => "CodeBlock"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [attr, string]}) do
    %Panpipe.AST.CodeBlock{
      string: string,
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end
end


################################################################################
# RawBlock Format String - Raw block

defmodule Panpipe.AST.RawBlock do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `RawBlock`.
  """

  use Panpipe.AST.Node, type: :block, fields: [:format, :string]

  def child_type(), do: nil

  def to_pandoc(%__MODULE__{format: format, string: string}) do
    %{"t" => "RawBlock", "c" => [format, string]}
  end
end

defimpl_ex Panpipe.Pandoc.RawBlock, %{"t" => "RawBlock"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [format, string]}) do
    %Panpipe.AST.RawBlock{
      format: format,
      string: string
    }
  end
end


################################################################################
# BlockQuote [Block] - Block quote (list of blocks)

defmodule Panpipe.AST.BlockQuote do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `BlockQuote`.
  """

  use Panpipe.AST.Node, type: :block

  def child_type(), do: :block

  def to_pandoc(%__MODULE__{children: children}) do
    %{
      "t" => "BlockQuote",
      "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)
    }
  end
end

defimpl_ex Panpipe.Pandoc.BlockQuote, %{"t" => "BlockQuote"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.BlockQuote{
      children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
    }
  end
end


################################################################################
# Helper struct: ListElement

defmodule Panpipe.AST.ListElement do
  use Panpipe.AST.Node, type: :block

  def child_type(), do: :block

  def from_pandoc(bullet_point) do
    %__MODULE__{
      children: Enum.map(bullet_point, &Panpipe.Pandoc.AST.Node.to_panpipe/1)
    }
  end

  def to_pandoc(%__MODULE__{children: children}) do
    Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)
  end
end

################################################################################
# Helper struct: ListAttributes

defmodule Panpipe.AST.ListAttributes do
  defstruct [:start, :number_style, :number_delimiter]

  # The various styles of list numbers
  @styles [
    "DefaultStyle",
    "Example",
    "Decimal",
    "LowerRoman",
    "UpperRoman",
    "LowerAlpha",
    "UpperAlpha"
  ]

  @doc """
  The possible values for the `number_style` field.
  """
  def styles(), do: @styles


  # The various delimiters of list numbers
  @delimiters [
    "DefaultDelim",
    "Period",
    "OneParen",
    "TwoParens"
  ]

  @doc """
  The possible values for the `number_delimiter` field.
  """
  def delimiters(), do: @delimiters


  def from_pandoc([start, %{"t" => number_style}, %{"t" => number_delimiter}]) do
    %__MODULE__{
      start: start,
      number_style: number_style,
      number_delimiter: number_delimiter
    }
  end

  def to_pandoc(%__MODULE__{start: start, number_style: number_style, number_delimiter: number_delimiter}) do
    [start, %{"t" => number_style}, %{"t" => number_delimiter}]
  end
end


################################################################################
# OrderedList ListAttributes [[Block]] - Ordered list (attributes and a list of items, each a list of blocks)

defmodule Panpipe.AST.OrderedList do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `OrderedList`.

  The list elements are stored as `Panpipe.AST.ListElement` structs and the
  list attributes in a `Panpipe.AST.ListAttributes` struct.
  """

  use Panpipe.AST.Node, type: :block, fields: [:list_attributes]

  def child_type(), do: :block # or ListElement?

  def to_pandoc(%__MODULE__{list_attributes: list_attributes, children: children}) do
    %{
      "t" => "OrderedList",
      "c" => [
        Panpipe.AST.ListAttributes.to_pandoc(list_attributes),
        Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)
      ]
    }
  end
end

defimpl_ex Panpipe.Pandoc.OrderedList, %{"t" => "OrderedList"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [list_attributes, children]}) do
    %Panpipe.AST.OrderedList{
      list_attributes: Panpipe.AST.ListAttributes.from_pandoc(list_attributes),
      children: Enum.map(children, &Panpipe.AST.ListElement.from_pandoc/1)
    }
  end
end


################################################################################
# BulletList [[Block]] - Bullet list (list of items, each a list of blocks)

defmodule Panpipe.AST.BulletList do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `BulletList`.

  The list elements are stored as `Panpipe.AST.ListElement` structs.
  """

  use Panpipe.AST.Node, type: :block

  def child_type(), do: :block # or ListElement?

  def to_pandoc(%__MODULE__{children: children}) do
    %{
      "t" => "BulletList",
      "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)
    }
  end
end

defimpl_ex Panpipe.Pandoc.BulletList, %{"t" => "BulletList"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.BulletList{
      children: Enum.map(children, &Panpipe.AST.ListElement.from_pandoc/1)
    }
  end
end


################################################################################
# DefinitionList [([Inline], [[Block]])] - Definition list Each list item is a pair consisting of a term (a list of inlines) and one or more definitions (each a list of blocks)

defmodule Panpipe.AST.DefinitionList do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `DefinitionList`.
  """

  use Panpipe.AST.Node, type: :block

  def child_type(), do: :block # or :definition_tuple

  # TODO: test in traversal tests, if we need to flatten the children

  def to_pandoc(%__MODULE__{children: children}) do
    %{
      "t" => "DefinitionList",
      "c" => Enum.map(children, fn [term, definition] ->
        [
          Enum.map(term, &Panpipe.AST.Node.to_pandoc/1),
          Enum.map(definition, fn block ->
            Enum.map(block, &Panpipe.AST.Node.to_pandoc/1)
          end)
        ]
      end)
    }
  end
end

defimpl_ex Panpipe.Pandoc.DefinitionList, %{"t" => "DefinitionList"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => definitions}) do
    %Panpipe.AST.DefinitionList{
      children: Enum.map(definitions, fn [term, definition] ->
        [
          Enum.map(term, &Panpipe.Pandoc.AST.Node.to_panpipe/1),
          Enum.map(definition, fn block ->
            Enum.map(block, &Panpipe.Pandoc.AST.Node.to_panpipe/1)
          end)
        ]
      end)
    }
  end
end


################################################################################
# Header Int Attr [Inline] - Header - level (integer) and text (inlines)

defmodule Panpipe.AST.Header do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Header`.
  """

  use Panpipe.AST.Node, type: :block, fields: [:level, attr: %Panpipe.AST.Attr{}]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{level: level, children: children, attr: attr}) do
    %{
      "t" => "Header",
      "c" => [level, Panpipe.AST.Attr.to_pandoc(attr), Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)]
    }
  end
end

defimpl_ex Panpipe.Pandoc.Header, %{"t" => "Header"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [level, attr, children]}) do
    %Panpipe.AST.Header{
      level: level,
      children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end
end


################################################################################
# HorizontalRule - Horizontal rule

defmodule Panpipe.AST.HorizontalRule do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `HorizontalRule`.
  """

  use Panpipe.AST.Node, type: :block

  def child_type(), do: nil

  def to_pandoc(%__MODULE__{}), do: %{"t" => "HorizontalRule"}
end

defimpl_ex Panpipe.Pandoc.HorizontalRule, %{"t" => "HorizontalRule"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(_), do: %Panpipe.AST.HorizontalRule{}
end


################################################################################
# Table [Inline] [Alignment] [Double] [TableCell] [[TableCell]] - Table, with caption, column alignments (required), relative column widths (0 = default), column headers (each a list of blocks), and rows (each a list of lists of blocks)

defmodule Panpipe.AST.Table do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Table`.
  """

  use Panpipe.AST.Node, type: :block,
      fields: [:caption, :column_alignments, :column_widths, :header, :rows]

  # Alignment of table columns
  @alignments [
    "AlignLeft",
    "AlignRight",
    "AlignCenter",
    "AlignDefault",
  ]

  @doc """
  The possible values for the `column_alignments` field.
  """
  def alignments(), do: @alignments


  def child_type(), do: :inline # or cells?

  def children(%__MODULE__{} = table) do
    # TODO: test in traversal tests, if we need to flatten the children
    # TODO #167558619: During traversal, it would be good if some context information would be available, like if a link was part of the table caption or a table cell etc.
    table.caption ++ List.flatten(table.header) ++ List.flatten(table.rows)
  end

  def transform(%__MODULE_{} = table, fun) do
    %{table |
      caption: Panpipe.AST.Node.do_transform_children(table.caption, table, fun),
      header: Enum.map(table.header, &(Panpipe.AST.Node.do_transform_children(&1, table, fun))),
      rows: Enum.map(table.rows, fn row ->
              Enum.map(row, fn columns ->
                Panpipe.AST.Node.do_transform_children(columns, table, fun)
              end)
            end)
    }
  end

  def to_pandoc(%__MODULE__{} = table) do
    %{
      "t" => "Table",
      "c" => [
        Enum.map(table.caption, &Panpipe.AST.Node.to_pandoc/1),
        Enum.map(table.column_alignments, &(%{"t" => &1})),
        table.column_widths,
        Enum.map(table.header, fn column ->
          Enum.map(column, &Panpipe.AST.Node.to_pandoc/1)
        end),
        Enum.map(table.rows, fn row ->
          Enum.map(row, fn column ->
            Enum.map(column, &Panpipe.AST.Node.to_pandoc/1)
          end)
        end)
      ]
    }
  end
end

defimpl_ex Panpipe.Pandoc.Table, %{"t" => "Table"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [caption, column_alignments, column_widths, header, rows]}) do
    %Panpipe.AST.Table{
      caption:
        Enum.map(caption, &Panpipe.Pandoc.AST.Node.to_panpipe/1),
      column_alignments:
        Enum.map(column_alignments, fn %{"t" => alignment} -> alignment end),
      column_widths: column_widths,
      header:
        Enum.map(header, fn column ->
          Enum.map(column, &Panpipe.Pandoc.AST.Node.to_panpipe/1)
        end),
      rows:
        Enum.map(rows, fn row ->
          Enum.map(row, fn column ->
            Enum.map(column, &Panpipe.Pandoc.AST.Node.to_panpipe/1)
          end)
        end)
    }
  end
end


################################################################################
# Div Attr [Block] - Generic block container with attributes

defmodule Panpipe.AST.Div do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Div`.
  """

  use Panpipe.AST.Node, type: :block, fields: [attr: %Panpipe.AST.Attr{}]

  def child_type(), do: :block

  def to_pandoc(%__MODULE__{children: children, attr: attr}) do
    %{
      "t" => "Div",
      "c" => [
        Panpipe.AST.Attr.to_pandoc(attr),
        Enum.map(children, &Panpipe.AST.Node.to_pandoc/1),
      ]
    }
  end
end

defimpl_ex Panpipe.Pandoc.Div, %{"t" => "Div"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [attr, text]}) do
    %Panpipe.AST.Div{
      children: text |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end
end


################################################################################
# Str String - Text (string)

defmodule Panpipe.AST.Str do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Str`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:string]

  def child_type(), do: nil

  def to_pandoc(%__MODULE__{string: str}), do: %{"t" => "Str", "c" => str}
end

defimpl_ex Panpipe.Pandoc.Str, %{"t" => "Str"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => str}), do: %Panpipe.AST.Str{string: str}
end


################################################################################
# Emph [Inline] - Emphasized text (list of inlines)

defmodule Panpipe.AST.Emph do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Emph`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:children]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children}) do
    %{"t" => "Emph", "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)}
  end
end

defimpl_ex Panpipe.Pandoc.Emph, %{"t" => "Emph"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.Emph{children: Enum.map(children, &Panpipe.Pandoc.AST.Node.to_panpipe/1)}
  end
end


################################################################################
# Strong [Inline] - Strongly emphasized text (list of inlines)

defmodule Panpipe.AST.Strong do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Strong`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:children]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children}) do
    %{"t" => "Strong", "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)}
  end
end

defimpl_ex Panpipe.Pandoc.Strong, %{"t" => "Strong"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.Strong{children: Enum.map(children, &Panpipe.Pandoc.AST.Node.to_panpipe/1)}
  end
end


################################################################################
# Strikeout [Inline] - Strikeout text (list of inlines)

defmodule Panpipe.AST.Strikeout do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Strikeout`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:children]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children}) do
    %{"t" => "Strikeout", "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)}
  end
end

defimpl_ex Panpipe.Pandoc.Strikeout, %{"t" => "Strikeout"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.Strikeout{children: Enum.map(children, &Panpipe.Pandoc.AST.Node.to_panpipe/1)}
  end
end


################################################################################
# Superscript [Inline] - Superscripted text (list of inlines)

defmodule Panpipe.AST.Superscript do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Superscript`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:children]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children}) do
    %{"t" => "Superscript", "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)}
  end
end

defimpl_ex Panpipe.Pandoc.Superscript, %{"t" => "Superscript"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.Superscript{children: Enum.map(children, &Panpipe.Pandoc.AST.Node.to_panpipe/1)}
  end
end


################################################################################
# Subscript [Inline] - Subscripted text (list of inlines)

defmodule Panpipe.AST.Subscript do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Subscript`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:children]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children}) do
    %{"t" => "Subscript", "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)}
  end
end

defimpl_ex Panpipe.Pandoc.Subscript, %{"t" => "Subscript"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.Subscript{children: Enum.map(children, &Panpipe.Pandoc.AST.Node.to_panpipe/1)}
  end
end


################################################################################
# SmallCaps [Inline] - Small caps text (list of inlines)

defmodule Panpipe.AST.SmallCaps do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Superscript`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:children]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children}) do
    %{"t" => "SmallCaps", "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)}
  end
end

defimpl_ex Panpipe.Pandoc.SmallCaps, %{"t" => "SmallCaps"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.SmallCaps{children: Enum.map(children, &Panpipe.Pandoc.AST.Node.to_panpipe/1)}
  end
end


################################################################################
# Quoted QuoteType [Inline] - Quoted text (list of inlines)

defmodule Panpipe.AST.Quoted do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Quoted`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:type, :children]

  @quote_types [
    "SingleQuote",
    "DoubleQuote",
  ]

  @doc """
  The possible values for the `type` field.
  """
  def quote_types(), do: @quote_types


  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children, type: quote_type}) do
    %{
      "t" => "Quoted",
      "c" => [
        %{"t" => quote_type},
        Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)
      ]
    }
  end
end

defimpl_ex Panpipe.Pandoc.Quoted, %{"t" => "Quoted"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [%{"t" => quote_type}, children]}) do
    %Panpipe.AST.Quoted{
      children: Enum.map(children, &Panpipe.Pandoc.AST.Node.to_panpipe/1),
      type: quote_type,
    }
  end
end


################################################################################
# Cite [Citation] [Inline] - Citation (list of inlines)

defmodule Panpipe.AST.Cite do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Cite`.

  The `citations` are kept in `Panpipe.AST.Cite.Citation` structs.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:citations, :children]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children, citations: citations}) do
    %{
      "t" => "Cite",
      "c" => [
        Enum.map(citations, &Panpipe.AST.Cite.Citation.to_pandoc/1),
        Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)
      ]
    }
  end
end

defimpl_ex Panpipe.Pandoc.Cite, %{"t" => "Cite"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [citations, children]}) do
    %Panpipe.AST.Cite{
      children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      citations: citations |> Enum.map(&Panpipe.AST.Cite.Citation.from_pandoc/1),
    }
  end
end

defmodule Panpipe.AST.Cite.Citation do
  defstruct [
    :id,       # String
    :prefix,   # [Inline]
    :suffix,   # [Inline]
    :mode,     # CitationMode
    :note_num, # Int
    :hash,
  ]

  @modes [
    "AuthorInText",
    "SuppressAuthor",
    "NormalCitation",
  ]

  @doc """
  The possible values for the `mode` field.
  """
  def modes(), do: @modes


  def from_pandoc(%{
        "citationHash" => hash,
        "citationId" => id,
        "citationMode" => %{"t" => mode},
        "citationNoteNum" => note_num,
        "citationPrefix" => prefix, # TODO: this is an inline - Should we consider this in the traversal, i.e. add it to the cite.children?
        "citationSuffix" => suffix  # TODO: this is an inline - Should we consider this in the traversal, i.e. add it to the cite.children?
      }) do
    %__MODULE__{
      id: id,
      prefix: prefix |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      suffix: suffix |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      mode: mode,
      note_num: note_num,
      hash: hash,
    }
  end

  def to_pandoc(%__MODULE__{} = citation) do
    %{
      "citationHash" => citation.hash,
      "citationId" => citation.id,
      "citationMode" => %{"t" => citation.mode},
      "citationNoteNum" => citation.note_num,
      "citationPrefix" => citation.prefix |> Enum.map(&Panpipe.AST.Node.to_pandoc/1),
      "citationSuffix" => citation.suffix |> Enum.map(&Panpipe.AST.Node.to_pandoc/1)
    }
  end
end


################################################################################
# Code Attr String - Inline code (literal)

defmodule Panpipe.AST.Code do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Code`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:string, attr: %Panpipe.AST.Attr{}]

  def child_type(), do: nil

  def to_pandoc(%__MODULE__{string: string, attr: attr}) do
    %{
      "t" => "Code",
      "c" => [Panpipe.AST.Attr.to_pandoc(attr), string]
    }
  end

  def language(%__MODULE__{attr: attr}),
    do: attr.classes |> List.wrap() |> List.first()
end

defimpl_ex Panpipe.Pandoc.Code, %{"t" => "Code"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [attr, string]}) do
    %Panpipe.AST.Code{
      string: string,
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end
end


################################################################################
# Space - Inter-word space

defmodule Panpipe.AST.Space do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Space`.
  """

  use Panpipe.AST.Node, type: :inline

  def child_type(), do: nil

  def to_pandoc(%__MODULE__{}), do: %{"t" => "Space"}
end

defimpl_ex Panpipe.Pandoc.Space, %{"t" => "Space"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(_), do: %Panpipe.AST.Space{}
end


################################################################################
# SoftBreak - Soft line break

defmodule Panpipe.AST.SoftBreak do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `SoftBreak`.
  """

  use Panpipe.AST.Node, type: :inline

  def child_type(), do: nil

  def to_pandoc(%__MODULE__{}), do: %{"t" => "SoftBreak"}
end

defimpl_ex Panpipe.Pandoc.SoftBreak, %{"t" => "SoftBreak"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(_), do: %Panpipe.AST.SoftBreak{}
end


################################################################################
# LineBreak - Hard line break

defmodule Panpipe.AST.LineBreak do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `LineBreak`.
  """

  use Panpipe.AST.Node, type: :inline

  def child_type(), do: nil

  def to_pandoc(%__MODULE__{}), do: %{"t" => "LineBreak"}
end

defimpl_ex Panpipe.Pandoc.LineBreak, %{"t" => "LineBreak"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(_), do: %Panpipe.AST.LineBreak{}
end


################################################################################
# Math MathType String - TeX math (literal)

# TODO: Does inline/block depend on math_type?
defmodule Panpipe.AST.Math do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Math`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:type, :string]

  # Types of math elements
  @math_types [
    "InlineMath",
    "DisplayMath",
  ]

  @doc """
  The possible values for the `type` field.
  """
  def math_types(), do: @math_types

  
  def child_type(), do: nil

  def to_pandoc(%__MODULE__{type: math_type, string: string}) do
    %{"t" => "Math", "c" => [%{"t" => math_type}, string]}
  end
end

defimpl_ex Panpipe.Pandoc.Math, %{"t" => "Math"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [%{"t" => math_type}, string]}) do
    %Panpipe.AST.Math{
      type: math_type,
      string: string
    }
  end
end


################################################################################
# RawInline Format String - Raw inline

defmodule Panpipe.AST.RawInline do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `RawInline`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:format, :string]

  def child_type(), do: nil

  def to_pandoc(%__MODULE__{format: format, string: string}) do
    %{"t" => "RawInline", "c" => [format, string]}
  end
end

defimpl_ex Panpipe.Pandoc.RawInline, %{"t" => "RawInline"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [format, string]}) do
    %Panpipe.AST.RawInline{
      format: format,
      string: string
    }
  end
end


################################################################################
# Link Attr [Inline] Target - Hyperlink: alt text (list of inlines), target

defmodule Panpipe.AST.Link do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Link`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:children, :target, title: "", attr: %Panpipe.AST.Attr{}]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children, target: target, title: title, attr: attr}) do
    %{
      "t" => "Link",
      "c" => [
        Panpipe.AST.Attr.to_pandoc(attr),
        Enum.map(children, &Panpipe.AST.Node.to_pandoc/1),
        [target, title]
      ]
    }
  end
end

defimpl_ex Panpipe.Pandoc.Link, %{"t" => "Link"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [attr, children, [target, title]]}) do
    %Panpipe.AST.Link{
      children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      target: target,
      title: title,
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end
end


################################################################################
# Image Attr [Inline] Target - Image: alt text (list of inlines), target

defmodule Panpipe.AST.Image do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Image`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:children, :target, title: "", attr: %Panpipe.AST.Attr{}]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children, target: target, title: title, attr: attr}) do
    %{
      "t" => "Image",
      "c" => [
        Panpipe.AST.Attr.to_pandoc(attr),
        Enum.map(children, &Panpipe.AST.Node.to_pandoc/1),
        [target, title]
      ]
    }
  end
end

defimpl_ex Panpipe.Pandoc.Image, %{"t" => "Image"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [attr, children, [target, title]]}) do
    %Panpipe.AST.Image{
      children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      target: target,
      title: title,
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end
end


################################################################################
# Note [Block] - Footnote or endnote

defmodule Panpipe.AST.Note do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Note`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:children]

  def child_type(), do: :block

  def to_pandoc(%__MODULE__{children: children}) do
    %{"t" => "Note", "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)}
  end
end

defimpl_ex Panpipe.Pandoc.Note, %{"t" => "Note"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.Note{children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1)}
  end
end


################################################################################
# Span Attr [Inline] - Generic inline container with attributes

defmodule Panpipe.AST.Span do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Span`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:children, attr: %Panpipe.AST.Attr{}]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children, attr: attr}) do
    %{
      "t" => "Span",
      "c" => [
        Panpipe.AST.Attr.to_pandoc(attr),
        Enum.map(children, &Panpipe.AST.Node.to_pandoc/1),
      ]
    }
  end
end

defimpl_ex Panpipe.Pandoc.Span, %{"t" => "Span"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [attr, children]}) do
    %Panpipe.AST.Span{
      children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end
end


################################################################################
# Null - Nothing

defmodule Panpipe.AST.Null do
  @moduledoc """
  A `Panpipe.AST.Null` for nodes of the Pandoc AST with the type `Null`.

  This type of node can be useful when you want to remove another node with
  the `Panpipe.AST.transform/2` function.
  """

  use Panpipe.AST.Node, type: :block

  def child_type(), do: :nil

  def to_pandoc(%__MODULE__{}), do: %{"t" => "Null"}
end

defimpl_ex Panpipe.Pandoc.Null, %{"t" => "Null"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(_), do: %Panpipe.AST.Null{}
end
