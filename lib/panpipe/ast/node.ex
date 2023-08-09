defmodule Panpipe.AST.Node do
  @moduledoc """
  Behaviour implemented by all nodes of the Panpipe AST.

  The Panpipe AST is a Elixir representation of the
  [Pandoc data structure for a format-neutral representation of documents](http://hackage.haskell.org/package/pandoc-types-1.17.5.4/docs/Text-Pandoc-Definition.html).
  Each of the nodes of this AST data structure is a struct implementing the `Panpipe.AST.Node`
  behaviour and directly matches the respective Pandoc element.

  Each node type implements Elixir's `Enumerable` protocol as a pre-order tree
  traversal.
  """

  # TODO: This attempt to define a type for struct implementing this behaviour is copied from RDF.Graph & co. and won't work probably ...
  @type t :: module

  @doc """
  Returns a list of the children of a node.
  """
  @callback children(t) :: [t]

  @doc """
  Returns the type of child expected for a AST node.

  This function returns either `:block` or `:inline`.
  """
  @callback child_type() :: atom

  @doc """
  Returns if the AST node module represents a block element.
  """
  @callback block?() :: bool

  @doc """
  Returns if the AST node module represents an inline element.
  """
  @callback inline?() :: bool

  @doc """
  Produces the Pandoc AST data structure of a Panpipe AST node.
  """
  @callback to_pandoc(t) :: map

  @doc """
  Transforms an Panpipe AST node recursively.

  see `Panpipe.AST.Node.transform/2`
  """
  @callback transform(t, fun) :: t

  @shared_fields parent: nil

  @doc """
  Produces the Pandoc AST data structure of the given Panpipe AST `node`.

  ## Examples

      iex> %Panpipe.AST.Header{level: 1, children: [%Panpipe.AST.Str{string: "Example"}]}
      ...> |> Panpipe.AST.Node.to_pandoc()
      %{
        "c" => [1, ["", [], []], [%{"c" => "Example", "t" => "Str"}]],
        "t" => "Header"
      }

  """
  def to_pandoc(%mod{} = node), do: mod.to_pandoc(node)

  @doc """
  Transforms the AST under the given Panpipe AST `node` by applying the given transformation function recursively.

  The given function will be passed all nodes in pre-order and will replace those
  nodes for which the transformation function `fun` returns a  non-`nil` replacement
  value.
  A node can also be replaced with a sequence of new nodes by returning a list of
  nodes in the transformation function.
  If you want to remove a node, you can return an empty list or a `Panpipe.AST.Null`
  node.

  The transformation will be applied recursively also on children of the replaced
  values. You can prohibit that by returning the replacement in a halt tuple like
  this: `{:halt, replacement}`.

  ## Examples

      Panpipe.ast!(input: "file.md")
      |> Panpipe.transform(fn
         %Panpipe.AST.Header{} = header ->
           %Panpipe.AST.Header{header | level: header.level + 1}
         _ -> nil
       end)

      Panpipe.ast!(input: "file.md")
      |> Panpipe.transform(fn
         %Panpipe.AST.Header{} = header ->
           {:halt, %Panpipe.AST.Header{header | level: header.level + 1}}
         _ -> nil
       end)

  """
  def transform(%mod{} = node, fun), do: mod.transform(node, fun)

  @doc """
  Returns if the given AST `node` is a block element.
  """
  def block?(node)
  def block?(%mod{}), do: mod.block?()

  @doc """
  Returns if the given AST `node` is an inline element.
  """
  def inline?(node)
  def inline?(%mod{}), do: mod.inline?()

  @doc """
  Returns the type of child expected for the given AST `node`.

  This function returns either `:block` or `:inline`.
  """
  def child_type(node)
  def child_type(%mod{}), do: mod.child_type()

  @doc false
  defmacro __using__(opts) do
    node_type = Keyword.fetch!(opts, :type)
    fields = fields(node_type, Keyword.get(opts, :fields, []))

    quote do
      @behaviour Panpipe.AST.Node
      import Panpipe.AST.Node

      defstruct unquote(fields)

      def children(node)
      def children(%{children: children}), do: children
      def children(_), do: []

      if unquote(node_type) == :block do
        def block?(), do: true
      else
        def block?(), do: false
      end

      if unquote(node_type) == :inline do
        def inline?(), do: true
      else
        def inline?(), do: false
      end

      def transform(node, fun), do: do_transform(node, fun)

      defimpl Panpipe.Pandoc.Conversion do
        def convert(node, opts) do
          with {:ok, result} <-
                 node
                 |> Panpipe.Document.fragment()
                 |> Panpipe.Document.to_pandoc()
                 |> Jason.encode!()
                 |> Panpipe.Pandoc.call(Keyword.put(opts, :from, :json)) do
            if result do
              Panpipe.Pandoc.Conversion.Utils.post_process(result, node, opts)
            end
          else
            _ -> nil
          end
        end
      end

      defimpl Enumerable do
        def member?(_node, _), do: {:error, __MODULE__}
        def count(_node), do: {:error, __MODULE__}
        def slice(_node), do: {:error, __MODULE__}

        def reduce(_, {:halt, acc}, _fun), do: {:halted, acc}

        def reduce(node, {:suspend, acc}, fun) do
          {:suspended, acc, &reduce(node, &1, fun)}
        end

        def reduce(node, {:cont, acc}, fun) do
          unquote(__CALLER__.module).children(node)
          |> Enum.reduce(fun.(node, acc), fn child, result ->
            Enumerable.reduce(%{child | parent: node}, result, fun)
          end)
        end
      end

      defoverridable children: 1, transform: 2
    end
  end

  @doc !"""
       This is a general implementation of the `Panpipe.AST.Node.transform/2` function.
       Do not use it directly, but instead call the `Panpipe.AST.Node.transform/2` implementation
       of a node, which might have a different implementation.
       """
  def do_transform(node, fun)

  def do_transform(%{children: children} = node, fun) do
    %{node | children: do_transform_children(children, node, fun)}
  end

  def do_transform(node, _), do: node

  @doc false
  def do_transform_children(children, node, fun) do
    Enum.flat_map(children, fn child ->
      case fun.(%{child | parent: node}) do
        {:halt, mapped_children} ->
          mapped_children
          |> List.wrap()
          |> Enum.map(fn mapped_child -> %{mapped_child | parent: nil} end)

        nil ->
          transform(child, fun)
          |> List.wrap()

        mapped_children ->
          mapped_children
          |> List.wrap()
          |> Enum.map(fn mapped_child ->
            transform(%{mapped_child | parent: nil}, fun)
          end)
      end
    end)
  end

  defp fields(:block, fields) do
    ([children: []] ++ @shared_fields)
    |> Keyword.merge(to_keywords(fields))
  end

  defp fields(:inline, fields) do
    @shared_fields
    |> Keyword.merge(to_keywords(fields))
  end

  defp to_keywords(list) do
    if Keyword.keyword?(list) do
      list
    else
      Enum.map(list, fn
        {_, _} = keyword -> keyword
        field -> {field, nil}
      end)
    end
  end
end
