defmodule Panpipe do
  alias Panpipe.Pandoc

  defdelegate pandoc(input_or_opts, opts \\ nil),  to: Pandoc, as: :call
  defdelegate pandoc!(input_or_opts, opts \\ nil), to: Pandoc, as: :call!

  defdelegate transform(node, fun), to: Panpipe.AST.Node

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

  def ast_fragment(input_or_opts, opts \\ nil) do
    with {:ok, pandoc_ast} <- ast(input_or_opts, opts) do
      case pandoc_ast do
        %Panpipe.Document{children: [%Panpipe.AST.Para{children: [fragment]}]} ->
          {:ok, fragment}

        %Panpipe.Document{children: [fragment]} ->
          {:ok, fragment}

        %Panpipe.Document{children: children} when is_list(children) ->
          {:ok, %Panpipe.AST.Plain{children: children}}

        _ -> {:error, "unable to extract ast_fragment from #{inspect pandoc_ast}"}
      end
    end
  end

  def ast_fragment!(input_or_opts, opts \\ nil) do
    with {:ok, result} <- ast_fragment(input_or_opts, opts) do
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
