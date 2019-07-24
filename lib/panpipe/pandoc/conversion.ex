defprotocol Panpipe.Pandoc.Conversion do
  def convert(source, opts)
end

defmodule Panpipe.Pandoc.Conversion.Utils do
  def post_process(result) do
    String.replace(result, ~r/\n$/, "") # TODO: Is there a faster way? Do we even really want that?
  end
end

defimpl Panpipe.Pandoc.Conversion, for: BitString do
  def convert(source, opts) do
    with {:ok, result} <- Panpipe.Pandoc.call(source, opts) do
      Panpipe.Pandoc.Conversion.Utils.post_process(result)
    else
      _ -> nil
    end
  end
end
