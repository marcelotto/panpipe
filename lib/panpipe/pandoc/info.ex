defmodule Panpipe.Pandoc.Info do
  @moduledoc false

  def read(file) do
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.filter(fn format -> format != "" end)
    |> Enum.map(&String.to_atom/1)
  end

  def read_without_flag(file) do
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.filter(fn format -> format != "" end)
    |> Enum.map(fn format -> String.slice(format, 1..-1//1) end)
    |> Enum.map(&String.to_atom/1)
  end
end
