# Panpipe

[![Hex.pm](https://img.shields.io/hexpm/v/panpipe.svg?style=flat-square)](https://hex.pm/packages/panpipe)


An Elixir wrapper around [Pandoc].


## Features

- convenient ways to call the `pandoc` functions from Elixir
- Elixir structs for the [Pandoc AST] - a read and writeable Markdown AST
- ways to traverse and transform the AST via Elixir pattern matching (and pipes maybe)
- ... everything you need to write [Pandoc filters] with Elixir


## Installation

You'll need to have [Pandoc installed](https://pandoc.org/installing.html). 

The Hex package can then be installed by adding `panpipe` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:panpipe, "~> 0.3"}
  ]
end
```


## Usage

### Calling Pandoc

Pandoc can be called with the `Panpipe.pandoc/2` function. Generally it takes the long-form arguments of Pandoc as the usual Keyword list options with dashes replaced by underscores, but there are a couple of differences. First, the input is either provided directly as a string as the first argument or when the input is another file via the `input` option.

```elixir
iex> Panpipe.pandoc("# Example doc", to: :latex)
{:ok, "\\hypertarget{example-doc}{%\n\\section{Example doc}\\label{example-doc}}\n"}
iex> Panpipe.pandoc(input: "file.md", output: "output.tex")
{:ok, nil}
iex> Panpipe.pandoc(input: "file.md", output: "output.pdf", pdf_engine: :xelatex, variable: "linkcolor=blue")
```

As you can see the `Panpipe.pandoc/2` returns an ok tuple in the success with the result as string if no output file is specified, or `nil` if the output was written to a file. If want directly get the result and fail in error cases, you can use the `Panpipe.pandoc!/2` function.

Extensions for the input and output format can be specified by providing a tuple with the format and either a list of extensions to be enabled or a map with the keys `enable` and `disable`.

``` elixir
Panpipe.pandoc("# Example doc", 
  from: {:markdown, [:emoji]}, 
  to: {:html, %{enable: [:emoji], disable: [:raw_html, :raw_attribute]}}
)
```

Another difference is that flag arguments of Pandoc must be provided as an option with the value `true`.

```elixir
Panpipe.pandoc("# Example doc", to: :html, standalone: true)
```

You can also call Pandoc with a specific output format with the `Panpipe.to_<format>/2` functions, which are available for every output format supported by Pandoc. Other than setting the `to` option they are just a `Panpipe.pandoc/2` call taking the same arguments.

```elixir
Panpipe.to_latex("# Example doc")

"# Example doc"
|> Panpipe.to_html(standalone: true)
```



### The Panpipe AST

You can get an AST representation of some input with the `Panpipe.ast/2` or `Panpipe.ast!/2` functions. The input and Pandoc options can be given in the same way as for the `Panpipe.pandoc/2` function described above. 

```elixir
iex> Panpipe.ast("# Example doc")
{:ok,
 %Panpipe.Document{
   children: [
     %Panpipe.AST.Header{
       attr: %Panpipe.AST.Attr{
         classes: [],
         identifier: "example-doc",
         key_value_pairs: %{}
       },
       children: [
         %Panpipe.AST.Str{parent: nil, string: "Example"},
         %Panpipe.AST.Space{parent: nil},
         %Panpipe.AST.Str{parent: nil, string: "doc"}
       ],
       level: 1,
       parent: nil
     }
   ],
   meta: nil,
   parent: nil
 }}
```

The AST structure is an exact representation of the Pandoc AST returned during the conversion to JSON, but in nice Elixir structs for the nodes. 

It can be traversed by using Elixirs `Enumerable` protocol which is implemented by all AST nodes and will yield the nodes in pre-order.

```elixir
Panpipe.ast!(input: "file.md")
|> Enum.filter(fn node -> match?(%Panpipe.AST.Link{}, node) end)
|> Enum.map(fn %Panpipe.AST.Link{target: target} -> target end)
```

The AST can be transformed with the `Panpipe.transform/2` function. The transformation will be called with all nodes and replace the result with result value unless it is `nil`. Here's an example showing how to increase the level of all headers:

```elixir
Panpipe.ast!(input: "file.md")
|> Panpipe.transform(fn 
     %Panpipe.AST.Header{} = header ->
       %Panpipe.AST.Header{header | level: header.level + 1}
     _ -> nil
   end)
```

It's also possible to replace a single node with a sequence of new nodes by returning a list of nodes in the transformation function.

You may have noted the `parent` member in the AST example above. This is something not present in the original Pandoc AST representation. All of the nodes in the AST returned by `Panpipe.ast/2` have `nil` as the `parent` value. But the nodes emitted during traversal with the `Enumerable` protocol and on the `Panpipe.transform/2` function will have set this field to the respective parent node (but not recursively up to the root), which gives an additional criterion to pattern match on.


## Contributing

see [CONTRIBUTING](CONTRIBUTING.md) for details.



## License and Copyright

(c) 2019-present Marcel Otto. MIT Licensed, see [LICENSE](LICENSE.md) for details.


[Pandoc]:           https://pandoc.org/
[Pandoc filters]:   https://pandoc.org/filters.html
[Pandoc AST]:       http://hackage.haskell.org/package/pandoc-types/docs/Text-Pandoc-Definition.html
