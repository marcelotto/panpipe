defmodule Panpipe.Document do
  use Panpipe.AST.Node, type: :block, fields: [:meta]

  def to_pandoc(%Panpipe.Document{children: children, meta: meta}) do
    %{
      "blocks" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1),
      "meta" => %{}, # TODO: meta
      "pandoc-api-version" => Panpipe.Pandoc.api_version(),
    }
  end


  def fragment(%{block: true} = node) do
    %__MODULE__{children: [node]}
  end

  def fragment(nodes) do
    fragment(%Panpipe.AST.Plain{children: List.wrap(nodes)})
  end
end

import ProtocolEx

defimpl_ex Panpipe.Pandoc.Document, %{"blocks" => _, "pandoc-api-version" => _}, for: Panpipe.Pandoc.AST.Node do
  def to_panpipe(%{"blocks" => blocks, "meta" => meta}) do
    %Panpipe.Document{
      children: blocks |> Enum.map(&Panpipe.Pandoc.AST.Node.to_panpipe/1),
      meta: nil, # TODO: meta
    }
  end
end
