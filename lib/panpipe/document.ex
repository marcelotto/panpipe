defmodule Panpipe.Document do
  @moduledoc """
  The root `Panpipe.AST.Node`.
  """

  use Panpipe.AST.Node, type: :block, fields: [:meta]

  def child_type(), do: :block

  def to_pandoc(%Panpipe.Document{children: children, meta: meta}) do
    %{
      "blocks" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1),
      "meta" => meta || %{},
      "pandoc-api-version" => Panpipe.Pandoc.api_version()
    }
  end

  @doc """
  Creates a document fragment from the given `node`.
  """
  def fragment(node)

  def fragment(%__MODULE__{} = document), do: document

  def fragment(node) do
    if Panpipe.AST.Node.block?(node) do
      %__MODULE__{children: [node]}
    else
      fragment(%Panpipe.AST.Plain{children: List.wrap(node)})
    end
  end
end

import ProtocolEx

defimpl_ex Panpipe.Pandoc.Document, %{"blocks" => _, "pandoc-api-version" => _},
  for: Panpipe.Pandoc.AST.Node do
  @moduledoc false

  def to_panpipe(%{"blocks" => blocks, "meta" => meta}) do
    %Panpipe.Document{
      children: blocks |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      # TODO: create a Panpipe.AST.Meta struct
      meta: meta
    }
  end
end
