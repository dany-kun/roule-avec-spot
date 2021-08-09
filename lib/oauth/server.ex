defmodule OAuth.Server do
  use Agent

  def fetch_oauth_code() do
    oauth_server_pid = Process.whereis(:oauth_server)

    if !oauth_server_pid || !Process.alive?(oauth_server_pid) do
      launch_server()
    end

    oauth_server_pid
  end

  defp launch_server() do
    pid = self()
    Task.async(fn -> OAuth.Server.OAuth.Plug.start(pid) end)
  end

  defmodule OAuth.Plug do
    use Plug.Router

    Plug.Builder.plug(:match)
    Plug.Builder.plug(:dispatch)

    def start(pid) do
      Process.register(pid, :oauth_server)

      Agent.start_link(fn -> pid end, name: __MODULE__)

      Plug.Cowboy.http(OAuth.Plug, port: 4000)
    end

    get "/spotify" do
      {pid, code} = extract_and_boradcast_code(conn)
      Kernel.send(pid, {:callback, {:spotify, code}})
      send_resp(conn, 200, "OK Spotify\n")
    end

    get "/youtube" do
      {pid, code} = extract_and_boradcast_code(conn)
      Kernel.send(pid, {:callback, {:youtube, code}})
      send_resp(conn, 200, "OK Youtube\n")
    end

    defp extract_and_boradcast_code(conn) do
      conn = fetch_query_params(conn)
      %{query_params: %{"code" => code}} = conn
      pid = Agent.get(__MODULE__, & &1)
      {pid, code}
    end

    match _ do
      send_resp(conn, 404, "not found\n")
    end
  end
end
