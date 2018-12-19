defmodule Panpipe.Document do
  use Panpipe.AST.Node, type: :block, fields: [:meta]

  def to_pandoc(%Panpipe.Document{children: children, meta: meta}) do
    %{
      "blocks" => Enum.map(children, &Panpipe.AST.Node.to_pandoc/1),
      "meta" => meta,
      "pandoc-api-version" => Panpipe.Pandoc.api_version(),
    }
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
