defprotocol Panpipe.Pandoc.Conversion do
  def convert(source, opts)
end

defimpl Panpipe.Pandoc.Conversion, for: BitString do
  def convert(source, opts) do
    with {:ok, result} <- Panpipe.Pandoc.call(source, opts) do
      String.trim(result)
    else
      _ -> nil
    end
  end
end
