defmodule Panpipe do
  alias Panpipe.Pandoc

  def ast(input_or_opts, opts \\ nil) do
    with {:ok, pandoc_ast} <- Pandoc.ast(input_or_opts, opts) do
      {:ok, Panpipe.Pandoc.AST.Node.to_panpipe(pandoc_ast)}
    end
  end

  def ast!(input_or_opts, opts \\ nil) do
    with {:ok, result} <- ast(input_or_opts, opts) do
      result
    else
      {:error, error} -> raise error
    end
  end


  Enum.each Panpipe.Pandoc.output_formats, fn output_format ->
    def unquote(String.to_atom("to_" <> to_string(output_format)))(input, opts \\ []) do
      Panpipe.Pandoc.Conversion.convert(input,
        Keyword.put(opts, :to, unquote(output_format)))
    end
  end

end
