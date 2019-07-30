defmodule Panpipe.AST.Node do

  @type t :: module

  @callback children(t) :: [t]

  @callback block?() :: bool
  @callback inline?() :: bool

  @callback child_type() :: atom

  @callback to_pandoc(t) :: map


  @shared_fields parent: nil


  def to_pandoc(%mod{} = node), do: mod.to_pandoc(node)

  def block?(%mod{}), do: mod.block?()
  def inline?(%mod{}), do: mod.inline?()

  def child_type(%mod{}), do: mod.child_type()


  @doc false
  defmacro __using__(opts) do
    node_type = Keyword.fetch!(opts, :type)
    fields = fields(node_type, Keyword.get(opts, :fields, []))

    quote do
      @behaviour Panpipe.AST.Node
      import Panpipe.AST.Node

      defstruct unquote(fields)

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

      defimpl Panpipe.Pandoc.Conversion do
        def convert(node, opts) do
          with {:ok, result} <-
                 node
                 |> Panpipe.Document.fragment()
                 |> Panpipe.Document.to_pandoc()
                 |> Jason.encode!()
                 |> Panpipe.Pandoc.call(Keyword.put(opts, :from, :json))
          do
            if result do
              Panpipe.Pandoc.Conversion.Utils.post_process(result)
            end
          else
            _ -> nil
          end
        end
      end

      defimpl Enumerable do
        def member?(_node, _), do: {:error, __MODULE__}
        def count(_node),      do: {:error, __MODULE__}
        def slice(_node),      do: {:error, __MODULE__}

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

      defoverridable [children: 1]
    end
  end

  defp fields(:block, fields) do
    [
      children: []
    ]
    ++ @shared_fields
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
      Enum.map list, fn
        {_, _} = keyword -> keyword
        field            -> {field, nil}
      end
    end
  end

end
