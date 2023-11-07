defmodule Panpipe do
  @moduledoc """
  An Elixir wrapper around Pandoc.

  The `Panpipe.Pandoc` module implements a wrapper around the Pandoc CLI.

  The `Panpipe.AST.Node` behaviour defines the functions implemented by all
  nodes of a Panpipe AST.
  """

  alias Panpipe.Pandoc

  defdelegate pandoc(input_or_opts, opts \\ nil), to: Pandoc, as: :call
  defdelegate pandoc!(input_or_opts, opts \\ nil), to: Pandoc, as: :call!

  defdelegate transform(node, fun), to: Panpipe.AST.Node

  @doc """
  Creates the Panpipe AST representation of some input.

  It accepts the same arguments as `Panpipe.Pandoc.call/2` which will be called
  implicitly to get the Pandoc AST representation.

  The result is returned in an `ok` tuple.
  """
  def ast(input_or_opts, opts \\ nil) do
    with {:ok, pandoc_ast} <- Pandoc.ast(input_or_opts, opts) do
      {:ok, Panpipe.Pandoc.AST.Node.to_panpipe(pandoc_ast)}
    end
  end

  @doc """
  Calls `ast/2` and delivers the result directly in success case, otherwise raises an error.
  """
  def ast!(input_or_opts, opts \\ nil) do
    with {:ok, result} <- ast(input_or_opts, opts) do
      result
    else
      {:error, error} -> raise error
    end
  end

  @doc """
  Creates an `Panpipe.AST.Node` of some input without the surrounding `Document` structure.
  """
  def ast_fragment(input_or_opts, opts \\ nil) do
    with {:ok, pandoc_ast} <- ast(input_or_opts, opts) do
      case pandoc_ast do
        %Panpipe.Document{children: [%Panpipe.AST.Para{children: [fragment]}]} ->
          {:ok, fragment}

        %Panpipe.Document{children: [fragment]} ->
          {:ok, fragment}

        %Panpipe.Document{children: children} when is_list(children) ->
          {:ok, %Panpipe.AST.Plain{children: children}}

        _ ->
          {:error, "unable to extract ast_fragment from #{inspect(pandoc_ast)}"}
      end
    end
  end

  @doc """
  Calls `ast_fragment/2` and delivers the result directly in success case, otherwise raises an error.
  """
  def ast_fragment!(input_or_opts, opts \\ nil) do
    with {:ok, result} <- ast_fragment(input_or_opts, opts) do
      result
    else
      {:error, error} -> raise error
    end
  end

  Enum.each(Panpipe.Pandoc.output_formats(), fn output_format ->
    @doc """
    Calls `pandoc/1` with the option `to: :#{to_string(output_format)}` automatically set.

    It also accepts `Panpipe.AST.Node`s. `pandoc/1` will then be called with
    Pandoc AST form of the node.

    By default, the converted output by Pandoc always ends with a newline. This
    can not be what you want, esp. when you convert small fragments by passing
    nodes directly. For this reason Panpipe will remove this newline by default
    for inline nodes, but keeps them on block nodes. You can control whether
    they should be removed manually with the `remove_trailing_newline` option.

    To enable or disable extensions for the target format, you can use the
    keyword options `:enable` and `:disable` with a list of extension atom names.

    Note: This function only works with directly passed strings or nodes. If you
    want to convert a file using the `input` option, you'll have to read the file
    first manually or use `pandoc/1` directly.
    """
    def unquote(String.to_atom("to_" <> to_string(output_format)))(input, opts \\ []) do
      Panpipe.Pandoc.Conversion.convert(
        input,
        Keyword.put(opts, :to, unquote(output_format))
      )
    end
  end)
end
