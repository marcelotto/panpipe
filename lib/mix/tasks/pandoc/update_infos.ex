defmodule Mix.Tasks.Pandoc.UpdateInfos do
  use Mix.Task

  alias Panpipe.Pandoc

  @shortdoc "Updates the information about the supported features of Pandoc."
  def run(_) do
    Mix.Shell.IO.cmd "pandoc --list-extensions > #{Pandoc.extensions_file()}"
    Mix.Shell.IO.cmd "pandoc --list-highlight-languages > #{Pandoc.highlight_languages_file()}"
    Mix.Shell.IO.cmd "pandoc --list-highlight-styles > #{Pandoc.highlight_styles_file()}"
    Mix.Shell.IO.cmd "pandoc --list-input-formats > #{Pandoc.input_formats_file()}"
    Mix.Shell.IO.cmd "pandoc --list-output-formats > #{Pandoc.output_formats_file()}"
  end
end
