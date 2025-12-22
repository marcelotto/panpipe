defmodule Panpipe.Generators do
  alias Panpipe.AST

  def ast_node do
  end

  def ast_node(:inline) do
    # TODO: add more ...
    [:str]
    |> Enum.map(&ast_node/1)
    |> StreamData.one_of()
  end

  def ast_node(:plain) do
    gen_node(AST.Plain, %{
      children: :children
    })
  end

  def ast_node(:header) do
    gen_node(AST.Header, %{
      level: StreamData.integer(1..6),
      children: :children,
      attr: :attr
    })
  end

  def ast_node(:str) do
    gen_node(AST.Str, %{
      string: :text
    })
  end

  def ast_node(:emph) do
    gen_node(AST.Emph, %{
      children: :children
    })
  end

  def ast_node(:strong) do
    gen_node(AST.Strong, %{
      children: :children
    })
  end

  def ast_node(:link) do
    gen_node(AST.Link, %{
      children: :formated_text,
      target: :url,
      title: :text,
      attr: :attr
    })
  end

  defp gen_node(type, data_schema) do
    data_schema
    |> Map.new(fn {key, data_gen} -> {key, gen(data_gen)} end)
    |> StreamData.fixed_map()
    |> StreamData.bind(fn map ->
      StreamData.constant(struct(type, map))
    end)
  end

  defp gen(type, args \\ [])

  defp gen(%StreamData{} = data, _), do: data

  defp gen(:children, _opts) do
    # TODO: add more ...
    [:inline]
    |> Enum.map(&ast_node/1)
    |> StreamData.one_of()
    |> StreamData.list_of()
  end

  defp gen(:text, _opts) do
    # TODO: generate mostly alphanumeric strings
    StreamData.binary()
  end

  defp gen(:formated_text, _opts) do
    # TODO: add :emph, :strong, ...
    [:str]
    |> Enum.map(&ast_node/1)
    |> StreamData.one_of()
    |> StreamData.list_of()
  end

  defp gen(:url, _opts) do
    # TODO: generate URL strings
    StreamData.binary()
  end

  defp gen(:attr, _opts) do
    StreamData.constant(Panpipe.AST.Attr.new())
  end
end
