defmodule Mix.Tasks.Playlist do
  use Mix.Task

  @requirements ["app.start"]

  @shortdoc "Create playlist from channel last video"
  def run(_) do
    Core.create_playlist()
  end
end
