import ProtocolEx

defprotocol_ex Panpipe.Pandoc.AST.Node do
  def to_panpipe(node)
end

################################################################################
# Plain

defmodule Panpipe.AST.Plain do
  use Panpipe.AST.Node, type: :block

  def to_pandoc(%Panpipe.AST.Plain{children: children}) do
    %{
      "t" => "Plain",
      "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)
    }
  end
end

defimpl_ex Panpipe.Pandoc.Plain, %{"t" => "Plain"}, for: Panpipe.Pandoc.AST.Node do
  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.Plain{
      children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1)
    }
  end
end

################################################################################
# Header

defmodule Panpipe.AST.Header do
  use Panpipe.AST.Node, type: :block, fields: [:level, :attr]

  def to_pandoc(%Panpipe.AST.Header{level: level, children: children, attr: attr}) do
    %{
      "t" => "Header",
      "c" => [level, attr, Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)]
    }
  end
end

defimpl_ex Panpipe.Pandoc.Header, %{"t" => "Header"}, for: Panpipe.Pandoc.AST.Node do
  def to_panpipe(%{"c" => [level, attr, children]}) do
    %Panpipe.AST.Header{
      level: level,
      children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      attr: nil, # TODO: attr
    }
  end
end

################################################################################
# Para

defmodule Panpipe.AST.Para do
  use Panpipe.AST.Node, type: :block

  def to_pandoc(%Panpipe.AST.Para{children: children}) do
    %{
      "t" => "Para",
      "c" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)
    }
  end
end

defimpl_ex Panpipe.Pandoc.Para, %{"t" => "Para"}, for: Panpipe.Pandoc.AST.Node do
  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.Para{
      children: children |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
    }
  end
end

################################################################################
# BulletList

defmodule Panpipe.AST.BulletList do
  use Panpipe.AST.Node, type: :block

  def to_pandoc(%Panpipe.AST.BulletList{children: children}) do
    %{
      "t" => "BulletList",
      "c" =>
        Enum.map(children, fn child_block ->
          Enum.map(child_block, &Panpipe.AST.Node.to_pandoc/1)
        end)
    }
  end
end

defimpl_ex Panpipe.Pandoc.BulletList, %{"t" => "BulletList"}, for: Panpipe.Pandoc.AST.Node do
  def to_panpipe(%{"c" => children}) do
    %Panpipe.AST.BulletList{
      children: Enum.map(children, &Panpipe.AST.BulletPoint.from_pandoc/1)
    }
  end
end

defmodule Panpipe.AST.BulletPoint do
  use Panpipe.AST.Node, type: :block

  def from_pandoc(bullet_point) do
    %Panpipe.AST.BulletPoint{
      children: Enum.map(bullet_point, &Panpipe.Pandoc.AST.Node.to_panpipe/1)
    }
  end

  def to_pandoc(%Panpipe.AST.BulletPoint{children: children}) do
    Enum.map(children, &Panpipe.AST.Node.to_pandoc/1)
  end
end


################################################################################
# Str String - Text (string)

defmodule Panpipe.AST.Str do
  use Panpipe.AST.Node, type: :inline, fields: [:string]

  def children(_), do: []

  def to_pandoc(%Panpipe.AST.Str{string: str}), do: %{"t" => "Str", "c" => str}
end

defimpl_ex Panpipe.Pandoc.Str, %{"t" => "Str"}, for: Panpipe.Pandoc.AST.Node do
  def to_panpipe(%{"c" => str}), do: %Panpipe.AST.Str{string: str}
end


################################################################################
# Emph [Inline] - Emphasized text (list of inlines)

defmodule Panpipe.AST.Emph do
  use Panpipe.AST.Node, type: :inline, fields: [:text]

  def children(%Panpipe.AST.Emph{text: node_seq}), do: node_seq

  def to_pandoc(%Panpipe.AST.Emph{text: node_seq}) do
    %{"t" => "Emph", "c" => Enum.map(node_seq, &Panpipe.AST.Node.to_pandoc/1)}
  end
end

defimpl_ex Panpipe.Pandoc.Emph, %{"t" => "Emph"}, for: Panpipe.Pandoc.AST.Node do
  def to_panpipe(%{"c" => text}) do
    %Panpipe.AST.Emph{text: text |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1)}
  end
end


################################################################################
# Strong [Inline] - Strongly emphasized text (list of inlines)

defmodule Panpipe.AST.Strong do
  use Panpipe.AST.Node, type: :inline, fields: [:text]

  def children(%Panpipe.AST.Strong{text: node_seq}), do: node_seq

  def to_pandoc(%Panpipe.AST.Strong{text: node_seq}) do
    %{"t" => "Strong", "c" => Enum.map(node_seq, &Panpipe.AST.Node.to_pandoc/1)}
  end
end

defimpl_ex Panpipe.Pandoc.Strong, %{"t" => "Strong"}, for: Panpipe.Pandoc.AST.Node do
  def to_panpipe(%{"c" => text}) do
    %Panpipe.AST.Strong{text: text |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1)}
  end
end

################################################################################
# Strikeout [Inline] - Strikeout text (list of inlines)

################################################################################
# Superscript [Inline] - Superscripted text (list of inlines)

################################################################################
# Subscript [Inline] - Subscripted text (list of inlines)

################################################################################
# SmallCaps [Inline] - Small caps text (list of inlines)

################################################################################
# Quoted QuoteType [Inline] - Quoted text (list of inlines)

################################################################################
# Cite [Citation] [Inline] - Citation (list of inlines)

################################################################################
# Code Attr String - Inline code (literal)

################################################################################
# Space - Inter-word space

defmodule Panpipe.AST.Space do
  use Panpipe.AST.Node, type: :inline

  def children(_), do: []

  def to_pandoc(%Panpipe.AST.Space{}), do: %{"t" => "Space"}
end

defimpl_ex Panpipe.Pandoc.Space, %{"t" => "Space"}, for: Panpipe.Pandoc.AST.Node do
  def to_panpipe(_), do: %Panpipe.AST.Space{}
end

################################################################################
# SoftBreak - Soft line break

################################################################################
# LineBreak - Hard line break

################################################################################
# Math MathType String - TeX math (literal)

################################################################################
# RawInline Format String - Raw inline

################################################################################
# Link Attr [Inline] Target - Hyperlink: alt text (list of inlines), target

defmodule Panpipe.AST.Link do
  use Panpipe.AST.Node, type: :inline, fields: [:text, :target, :title, :attr]

  def children(%Panpipe.AST.Link{text: node_seq}), do: node_seq

  def to_pandoc(%Panpipe.AST.Link{text: node_seq, target: target, title: title, attr: attr}) do
    %{
      "t" => "Link",
      "c" => [
        attr,
        Enum.map(node_seq, &Panpipe.AST.Node.to_pandoc/1),
        [target, title]
      ]
    }
  end
end

defimpl_ex Panpipe.Pandoc.Link, %{"t" => "Link"}, for: Panpipe.Pandoc.AST.Node do
  def to_panpipe(%{"c" => [attr, alt_text, [target, title]]}) do
    %Panpipe.AST.Link{
      text: alt_text |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      target: target,
      title: title,
      attr: nil, # TODO: attr
    }
  end
end


################################################################################
# Image Attr [Inline] Target - Image: alt text (list of inlines), target

################################################################################
# Note [Block] - Footnote or endnote

################################################################################
# Span Attr [Inline] - Generic inline container with attributes
