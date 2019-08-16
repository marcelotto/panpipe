defprotocol Panpipe.Pandoc.Conversion do
  @moduledoc !"""
  A protocol for conversion of `Panpipe.AST.Node`s or strings to any format supported by Pandoc.
  """

  def convert(source, opts)
end

defmodule Panpipe.Pandoc.Conversion.Utils do
  @moduledoc false

  def post_process(result, source, opts) do
    if Keyword.get(opts, :remove_trailing_newline, remove_trailing_newline?(source)) do
      String.replace(result, ~r/\n$/, "")
    else
      result
    end
  end

  defp remove_trailing_newline?(%node_type{}), do: node_type.inline?()
  defp remove_trailing_newline?(_), do: false
end

defimpl Panpipe.Pandoc.Conversion, for: BitString do
  def convert(source, opts) do
    with {:ok, result} <- Panpipe.Pandoc.call(source, opts) do
      Panpipe.Pandoc.Conversion.Utils.post_process(result, source, opts)
    else
      _ -> nil
    end
  end
end
