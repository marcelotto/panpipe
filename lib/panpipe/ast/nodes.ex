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
      children: Enum.map(children, &Panpipe.Pandoc.AST.Node.to_panpipe/1),
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
# Helper struct: Caption

defmodule Panpipe.AST.Caption do
  defstruct short_caption: nil, blocks: [], parent: nil

  def from_pandoc([short_caption, blocks]) do
    %__MODULE__{
      short_caption: short_caption,
      blocks: Enum.map(blocks, &Panpipe.Pandoc.AST.Node.to_panpipe/1)
    }
  end

  def to_pandoc(%__MODULE__{short_caption: short_caption, blocks: blocks}) do
    [
      short_caption,
      Enum.map(blocks, &Panpipe.AST.Node.to_pandoc/1)
    ]
  end

  def transform(%__MODULE__{} = caption, table, fun) do
    %__MODULE__{caption |
      blocks: Panpipe.AST.Node.do_transform_children(caption.blocks, %{caption | parent: table}, fun)
    }
  end
end

################################################################################
# Helper struct: ColSpec

defmodule Panpipe.AST.ColSpec do
  defstruct alignment: "AlignDefault", col_width: "ColWidthDefault"

  # Alignment of table columns
  @alignments [
    "AlignLeft",
    "AlignRight",
    "AlignCenter",
    "AlignDefault",
  ]

  @doc """
  The possible values for the `alignment` field.
  """
  def alignments(), do: @alignments

  def from_pandoc([%{"t" => alignment}, col_width]) do
    %__MODULE__{alignment: alignment, col_width: from_pandoc_col_width(col_width)}
  end

  def from_pandoc_col_width(%{"t" => col_width}), do: col_width
  def from_pandoc_col_width(col_width), do: col_width

  def to_pandoc(%__MODULE__{alignment: alignment, col_width: col_width}) do
    [%{"t" => alignment}, to_pandoc_col_width(col_width)]
  end

  def to_pandoc_col_width(col_width) when is_binary(col_width), do: %{"t" => col_width}
  def to_pandoc_col_width(col_width), do: col_width
end

################################################################################
# Helper struct: TableHead

defmodule Panpipe.AST.TableHead do
  defstruct rows: [], attr: %Panpipe.AST.Attr{}, parent: nil

  def from_pandoc([attr, rows]) do
    %__MODULE__{
      rows: Enum.map(rows, &Panpipe.AST.Row.from_pandoc/1),
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end

  def to_pandoc(%__MODULE__{attr: attr, rows: rows}) do
    [
      Panpipe.AST.Attr.to_pandoc(attr),
      Enum.map(rows, &Panpipe.AST.Row.to_pandoc/1),
    ]
  end

  def children(%__MODULE__{rows: rows}), do: Enum.flat_map(rows, &Panpipe.AST.Row.children/1)

  def transform(%__MODULE__{} = table_head, table, fun) do
    %__MODULE__{table_head |
      rows: Enum.map(table_head.rows, &(Panpipe.AST.Row.transform(&1, %{table_head | parent: table}, fun)))
    }
  end
end

################################################################################
# Helper struct: TableFoot

defmodule Panpipe.AST.TableFoot do
  defstruct rows: [], attr: %Panpipe.AST.Attr{}, parent: nil

  def from_pandoc([attr, rows]) do
    %__MODULE__{
      rows: Enum.map(rows, &Panpipe.AST.Row.from_pandoc/1),
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end

  def to_pandoc(%__MODULE__{attr: attr, rows: rows}) do
    [
      Panpipe.AST.Attr.to_pandoc(attr),
      Enum.map(rows, &Panpipe.AST.Row.to_pandoc/1),
    ]
  end

  def children(%__MODULE__{rows: rows}), do: Enum.flat_map(rows, &Panpipe.AST.Row.children/1)

  def transform(%__MODULE__{} = table_foot, table, fun) do
    %__MODULE__{table_foot |
      rows: Enum.map(table_foot.rows, &(Panpipe.AST.Row.transform(&1, %{table_foot | parent: table}, fun)))
    }
  end
end

################################################################################
# Helper struct: TableBody

defmodule Panpipe.AST.TableBody do
  defstruct row_head_columns: 0,
            intermediate_head_rows: [],
            intermediate_body_rows: [],
            attr: %Panpipe.AST.Attr{},
            parent: nil

  def from_pandoc([attr, row_head_columns, intermediate_head_rows, intermediate_body_rows]) do
    %__MODULE__{
      row_head_columns: row_head_columns,
      intermediate_head_rows: Enum.map(intermediate_head_rows, &Panpipe.AST.Row.from_pandoc/1),
      intermediate_body_rows: Enum.map(intermediate_body_rows, &Panpipe.AST.Row.from_pandoc/1),
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end

  def to_pandoc(%__MODULE__{} = table_body) do
    [
      Panpipe.AST.Attr.to_pandoc(table_body.attr),
      table_body.row_head_columns,
      Enum.map(table_body.intermediate_head_rows, &Panpipe.AST.Row.to_pandoc/1),
      Enum.map(table_body.intermediate_body_rows, &Panpipe.AST.Row.to_pandoc/1),
    ]
  end

  def children(%__MODULE__{
    intermediate_head_rows: intermediate_head_rows,
    intermediate_body_rows: intermediate_body_rows
  }) do
    Enum.flat_map(intermediate_head_rows, &Panpipe.AST.Row.children/1) ++
      Enum.flat_map(intermediate_body_rows, &Panpipe.AST.Row.children/1)
  end

  def transform(%__MODULE__{} = table_foot, table, fun) do
    table_foot_with_parent =%{table_foot | parent: table}
    %__MODULE__{table_foot |
      intermediate_head_rows:
        Enum.map(table_foot.intermediate_head_rows, &(Panpipe.AST.Row.transform(&1, table_foot_with_parent, fun))),
      intermediate_body_rows:
        Enum.map(table_foot.intermediate_body_rows, &(Panpipe.AST.Row.transform(&1, table_foot_with_parent, fun)))
    }
  end
end

################################################################################
# Helper struct: Row

defmodule Panpipe.AST.Row do
  defstruct cells: [], attr: %Panpipe.AST.Attr{}, parent: nil

  def from_pandoc([attr, cells]) do
    %__MODULE__{
      cells: Enum.map(cells, &Panpipe.AST.Cell.from_pandoc/1),
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end

  def to_pandoc(%__MODULE__{attr: attr, cells: cells}) do
    [
      Panpipe.AST.Attr.to_pandoc(attr),
      Enum.map(cells, &Panpipe.AST.Cell.to_pandoc/1),
    ]
  end

  def children(%__MODULE__{cells: cells}), do: Enum.flat_map(cells, &Panpipe.AST.Cell.children/1)

  def transform(%__MODULE__{} = row, parent, fun) do
    %__MODULE__{row |
      cells: Enum.map(row.cells, &(Panpipe.AST.Cell.transform(&1, %{row | parent: parent}, fun)))
    }
  end
end

################################################################################
# Helper struct: Cell

defmodule Panpipe.AST.Cell do
  defstruct blocks: [],
            alignment: "AlignDefault",
            row_span: 1,
            col_span: 1,
            attr: %Panpipe.AST.Attr{},
            parent: nil

  def from_pandoc([attr, %{"t" => alignment}, row_span, col_span, blocks]) do
    %__MODULE__{
      blocks: Enum.map(blocks, &Panpipe.Pandoc.AST.Node.to_panpipe/1),
      alignment: alignment,
      row_span: row_span,
      col_span: col_span,
      attr: Panpipe.AST.Attr.from_pandoc(attr)
    }
  end

  def to_pandoc(%__MODULE__{} = cell) do
    [
      Panpipe.AST.Attr.to_pandoc(cell.attr),
      %{"t" => cell.alignment},
      cell.row_span,
      cell.col_span,
      Enum.map(cell.blocks, &Panpipe.AST.Node.to_pandoc/1)
    ]
  end

  def children(%__MODULE__{blocks: blocks}), do: blocks

  def transform(%__MODULE__{} = cell, parent, fun) do
    %__MODULE__{cell |
      blocks: Panpipe.AST.Node.do_transform_children(cell.blocks, %{cell | parent: parent}, fun)
    }
  end
end

################################################################################
# Table Attr Caption [ColSpec] TableHead [TableBody] TableFoot - Table, with attributes, caption, optional short caption, column alignments and widths (required), table head, table bodies, and table foot

defmodule Panpipe.AST.Table do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Table`.
  """

  use Panpipe.AST.Node, type: :block,
                        fields: [
                          :col_spec,
                          table_head: %Panpipe.AST.TableHead{},
                          table_bodies: [],
                          table_foot: %Panpipe.AST.TableFoot{},
                          caption: %Panpipe.AST.Caption{},
                          attr: %Panpipe.AST.Attr{}
                        ]

  def child_type(), do: :inline # or cells?

  def children(%__MODULE__{} = table) do
    # TODO: test in traversal tests, if we need to flatten the children
    # TODO #167558619: During traversal, it would be good if some context information would be available, like if a link was part of the table caption or a table cell etc.
    table.caption.blocks ++
    Panpipe.AST.TableHead.children(table.table_head) ++
    Enum.flat_map(table.table_bodies, &Panpipe.AST.TableBody.children/1) ++
    Panpipe.AST.TableHead.children(table.table_foot)
  end

  def transform(%__MODULE__{} = table, fun) do
    %{table |
      caption: Panpipe.AST.Caption.transform(table.caption, table, fun),
      table_head: Panpipe.AST.TableHead.transform(table.table_head, table, fun),
      table_bodies: Enum.map(table.table_bodies, &Panpipe.AST.TableBody.transform(&1, table, fun)),
      table_foot: Panpipe.AST.TableFoot.transform(table.table_foot, table, fun)
    }
  end

  def to_pandoc(%__MODULE__{} = table) do
    %{
      "t" => "Table",
      "c" => [
        Panpipe.AST.Attr.to_pandoc(table.attr),
        Panpipe.AST.Caption.to_pandoc(table.caption),
        Enum.map(table.col_spec, &Panpipe.AST.ColSpec.to_pandoc/1),
        Panpipe.AST.TableHead.to_pandoc(table.table_head),
        Enum.map(table.table_bodies, &Panpipe.AST.TableBody.to_pandoc/1),
        Panpipe.AST.TableFoot.to_pandoc(table.table_foot)
      ]
    }
  end
end

defimpl_ex Panpipe.Pandoc.Table, %{"t" => "Table"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [attr, caption, col_spec, table_head, table_body, table_foot]}) do
    %Panpipe.AST.Table{
      caption: Panpipe.AST.Caption.from_pandoc(caption),
      col_spec: Enum.map(col_spec, &Panpipe.AST.ColSpec.from_pandoc/1),
      table_head: Panpipe.AST.TableHead.from_pandoc(table_head),
      table_bodies: Enum.map(table_body, &Panpipe.AST.TableBody.from_pandoc/1),
      table_foot: Panpipe.AST.TableFoot.from_pandoc(table_foot),
      attr: Panpipe.AST.Attr.from_pandoc(attr)
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
# Underling [Inline] - Underlined text (list of inlines)

defmodule Panpipe.AST.Underline do
  @moduledoc """
  A `Panpipe.AST.Node` for nodes of the Pandoc AST with the type `Underline`.
  """

  use Panpipe.AST.Node, type: :inline, fields: [:children]

  def child_type(), do: :inline

  def to_pandoc(%__MODULE__{children: children}) do
    %{"t" => "Underline", "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)}
  end
end

defimpl_ex Panpipe.Pandoc.Underline, %{"t" => "Underline"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.Underline{children: Enum.map(children, &Panpipe.Pandoc.AST.Node.to_panpipe/1)}
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
# Figure Attr Caption [Block] - Figure, with attributes, caption, and content (list of blocks)

defmodule Panpipe.AST.Figure do
  @moduledoc """
  A `Panpipe.AST.Figure` for nodes of the Pandoc AST with the type `Figure`.
  the `Panpipe.AST.transform/2` function.
  """

  use Panpipe.AST.Node, type: :block,
                        fields: [
                          caption: %Panpipe.AST.Caption{},
                          attr: %Panpipe.AST.Attr{}
                        ]


  def child_type(), do: :block

  def to_pandoc(%__MODULE__{} = figure) do
    %{
      "t" => "Figure",
      "c" => [
        Panpipe.AST.Attr.to_pandoc(figure.attr),
        Panpipe.AST.Caption.to_pandoc(figure.caption),
        Enum.map(figure.children, &Panpipe.AST.Node.to_pandoc/1),
      ]
    }
  end

end

defimpl_ex Panpipe.Pandoc.Figure, %{"t" => "Figure"}, for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"c" => [attr, caption, text]}) do
    %Panpipe.AST.Figure{
      caption: Panpipe.AST.Caption.from_pandoc(caption),
      attr: Panpipe.AST.Attr.from_pandoc(attr),
      children: text |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1)
    }
  end
end
