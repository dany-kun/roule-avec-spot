defmodule Mix.Tasks.Playlist do
  use Mix.Task

  @shortdoc "Create playlist from channel last video"
  def run(_) do
    children = [
      {OAuth.Cache, %{}}
    ]

    opts = [strategy: :one_for_one, name: Bootstrap.Supervisor]
    Supervisor.start_link(children, opts)
    Core.create_playlist()
  end
end
