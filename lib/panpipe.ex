defmodule Panpipe do

  Enum.each Panpipe.Pandoc.output_formats, fn output_format ->
    def unquote(String.to_atom("to_" <> to_string(output_format)))(input, opts \\ []) do
      Panpipe.Pandoc.Conversion.convert(input,
        Keyword.put(opts, :to, unquote(output_format)))
    end
  end

end
