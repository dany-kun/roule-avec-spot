defmodule App do
  use Application

  def start(_type, _args) do
    children = [
      {OAuth.Cache, %{}}
    ]

    opts = [strategy: :one_for_one, name: Bootstrap.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
