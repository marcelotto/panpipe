defmodule Panpipe.Pandoc do
  @moduledoc """
  Wrapper around the `pandoc` CLI.

  See the [Pandoc Manual](https://pandoc.org/MANUAL.html).
  """

  @panpipe_options ~w[remove_trailing_newline]a

  @pandoc "pandoc"

  @api_version [1, 17, 5, 4]

  @doc """
  The Pandoc API version against which Panpipe operates.

  This version will be used in the generated Pandoc documents.
  """
  def api_version(), do: @api_version

  @doc """
  The version of the Pandoc runtime Panpipe is using.
  """
  def version, do: extract_from_version_string ~R/pandoc (\d+\.\d+.*)/

  @doc """
  The data directory of the Pandoc runtime Panpipe is using.
  """
  def data_dir, do: extract_from_version_string ~R/Default user data directory: (.+)/

  defp extract_from_version_string(regex) do
    with {:ok, version_string} <- call(version: true),
         [_, match]            <- Regex.run(regex, version_string) do
      match
    else
      _ -> nil
    end
  end

  @info_path "priv/pandoc/info"
  @input_formats_file       Path.join(@info_path, "input-formats.txt")
  @output_formats_file      Path.join(@info_path, "output-formats.txt")
  @extensions_file          Path.join(@info_path, "extensions.txt")
  @highlight_languages_file Path.join(@info_path, "highlight-languages.txt")
  @highlight_styles_file    Path.join(@info_path, "highlight-styles.txt")

  @doc false
  def input_formats_file, do: @input_formats_file
  @doc false
  def output_formats_file, do: @output_formats_file
  @doc false
  def extensions_file, do: @extensions_file
  @doc false
  def highlight_languages_file, do: @highlight_languages_file
  @doc false
  def highlight_styles_file, do: @highlight_styles_file

  @external_resource @input_formats_file
  @external_resource @output_formats_file
  @external_resource @extensions_file
  @external_resource @highlight_languages_file
  @external_resource @highlight_styles_file

  @input_formats       Panpipe.Pandoc.Info.read(@input_formats_file)
  @output_formats      Panpipe.Pandoc.Info.read(@output_formats_file)
  @highlight_languages Panpipe.Pandoc.Info.read(@highlight_languages_file)
  @highlight_styles    Panpipe.Pandoc.Info.read(@highlight_styles_file)
  @extensions          Panpipe.Pandoc.Info.read_without_flag(@extensions_file)

  @doc """
  The list of input formats supported by Pandoc.
  """
  def input_formats(), do: @input_formats

  @doc """
  The list of output formats supported by Pandoc.
  """
  def output_formats(), do: @output_formats

  @doc """
  The list of languages for which Pandoc supports syntax highlighting in code blocks.
  """
  def highlight_languages(), do: @highlight_languages

  @doc """
  The list of highlighting styles supported by Pandoc.
  """
  def highlight_styles(), do: @highlight_styles

  @doc """
  The list of available Pandoc extension.
  """
  def extensions(), do: @extensions


  @doc """
  Calls the `pandoc` command.

  For a description of the arguments refer to the [Pandoc User’s Guide](http://pandoc.org/MANUAL.html).

  You can provide any of Pandoc's supported options in their long form without
  the leading double dashes and all other dashes replaced by underscores.

  Other than that, the only difference are a couple of default values:

  - Input is provided either directly as a string of content as the first argument
    or via the `input` option when it is a path to a file
  - Extensions for the input and output format can be specified by providing a
    tuple with the format and either a list of extensions to be enabled or a map
    with the keys `enable` and `disable`.
  - Flag options must provide a `true` value, eg. the `standalone` option can be set
    with the option `standalone: true`

  ## Examples

      iex> "# A Markdown Document\\nLorem ipsum" |> Panpipe.Pandoc.call()
      {:ok, ~s[<h1 id=\"a-markdown-document\">A Markdown Document</h1>\\n<p>Lorem ipsum</p>\\n]}

      iex> "# A Markdown Document\\n..." |> Panpipe.Pandoc.call(output: "test/output/example.html")
      {:ok, nil}

      iex> Panpipe.Pandoc.call(input: "test/fixtures/example.md")
      {:ok, ~s[<h1 id=\"a-markdown-document\">A Markdown Document</h1>\\n<p>Lorem ipsum</p>\\n]}

      iex> Panpipe.Pandoc.call(input: "test/fixtures/example.md", output: "test/output/example.html")
      {:ok, nil}

  """
  def call(input_or_opts, opts \\ nil) do
    opts = normalize_opts(input_or_opts, opts)
    with {:ok, %Rambo{status: 0} = result} <- exec(opts) do
      {:ok, output(result, opts)}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Calls `call/2` and delivers the result directly in success case, otherwise raises an error.
  """
  def call!(input_or_opts, opts \\ nil) do
    with {:ok, result} <- call(input_or_opts, opts) do
      result
    else
      {:error, error} -> raise error
    end
  end

  defp normalize_opts(input, opts) when is_binary(input) do
    opts
    |> List.wrap()
    |> Keyword.put(:input, {:data, input})
  end

  defp normalize_opts(opts, nil) when is_list(opts), do: opts

  defp exec(opts) do
    case Keyword.pop(opts, :input) do
      {input_file, opts} when is_binary(input_file) ->
        Rambo.run(@pandoc, [input_file | build_opts(opts)])

      {{:data, data}, opts} ->
        Rambo.run(@pandoc, build_opts(opts), in: data)

      {nil, _} ->
        if non_conversion_command?(opts) do
          Rambo.run(@pandoc, build_opts(opts))
        else
          raise "No input specified."
        end
    end
  end

  defp non_conversion_command?(opts) do
    Keyword.has_key?(opts, :version)
  end

  defp output(result, opts) do
    case Keyword.get(opts, :output) do
      nil   -> result.out
      _file -> nil
    end
  end

  defp build_opts(opts) do
    opts
    |> set_format_extensions(:to)
    |> set_format_extensions(:from)
    |> Enum.reject(&panpipe_option?/1)
    |> Enum.map(&build_opt/1)
  end

  defp panpipe_option?({opt, _}), do: opt in @panpipe_options

  defp build_opt({opt, true}),  do: "#{build_opt(opt)}"
  defp build_opt({opt, value}), do: "#{build_opt(opt)}=#{to_string(value)}"

  defp build_opt(opt) when is_atom(opt),
    do: "--#{opt |> to_string() |> String.replace("_", "-")}"

  defp set_format_extensions(opts, key) do
    if format_extensions = format_extensions(Keyword.get(opts, key)) do
      Keyword.put(opts, key, format_extensions)
    else
      opts
    end
  end

  defp format_extensions({format, extensions}) when is_list(extensions) do
    format_extensions({format, %{enable: extensions}})
  end

  defp format_extensions({format, %{} = extensions}) do
    to_string(format) <>
    extension_seq(extensions[:enable], "+") <>
    extension_seq(extensions[:disable], "-")
  end

  defp format_extensions(_), do: nil

  defp extension_seq([], _), do: ""
  defp extension_seq(nil, _), do: ""
  defp extension_seq(extensions, prefix) do
    prefix <> (
      extensions
      |> Enum.map(&to_string/1)
      |> Enum.intersperse(prefix)
      |> Enum.join()
    )
  end

  @doc """
  Returns the Pandoc AST of the input.
  """
  def ast(input_or_opts, opts \\ nil) do
    opts = normalize_opts(input_or_opts, opts)
    with {:ok, json} <- opts |> Keyword.put(:to, "json") |> call() do
      Jason.decode(json)
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
end
