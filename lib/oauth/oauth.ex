defmodule OAuth do
  @doc "Define the uri the user must log to"
  @callback uri :: String.t()

  @doc "Exchange a oauth code for oauth access and refresh tokens"
  @callback exchange_code!({atom(), String.t()}) :: %{
              access_token: String.t(),
              refresh_token: String.t()
            }

  @doc "Get a new access token from a refresh token"
  @callback refresh_access_token!(String.t()) :: String.t()
  @doc "Look for a refresh token from the configuration"
  @callback get_refresh_token_from_env() :: String.t() | nil

  def access_token!(impl) do
    %{access_token: access_token} =
      OAuth.Cache.get(fn cache -> cache[impl] end) || refresh_access_token!(impl) ||
        oauth_tokens!(impl)

    access_token
  end

  def refresh_access_token!(impl) do
    refresh_token =
      OAuth.Cache.get(fn cache -> cache[impl] end) || impl.get_refresh_token_from_env()

    refresh_access_token!(impl, refresh_token)
  end

  defp refresh_access_token!(_impl, nil), do: nil

  defp refresh_access_token!(impl, %{refresh_token: refresh_token}),
    do: impl.refresh_access_token!(refresh_token)

  defp refresh_access_token!(impl, refresh_token) when is_binary(refresh_token),
    do: impl.refresh_access_token!(refresh_token)

  def oauth_tokens!(impl) do
    uri = impl.uri()
    code = get_code!(uri)
    %{access_token: access_token, refresh_token: refresh_token} = impl.exchange_code!(code)

    tokens = %{access_token: access_token, refresh_token: refresh_token}

    OAuth.Cache.store(fn cache -> Map.put(cache, impl, tokens) end)

    tokens
  end

  defp get_code!(uri) do
    IO.puts("Please open #{uri} in your browser")
    OAuth.Server.fetch_oauth_code()

    receive_code()
  end

  defp receive_code do
    receive do
      {:callback, code} -> code
      _ -> receive_code()
    end
  end
end

defmodule OAuth.Cache do
  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def get(get_fn) do
    Agent.get(__MODULE__, get_fn)
  end

  def store(update_fn) do
    Agent.update(__MODULE__, update_fn)
  end
end

defmodule OAuth.Cache.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {OAuth.Cache, %{}}
    ]

    opts = [strategy: :one_for_one, name: Bootstrap.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
