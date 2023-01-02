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
      get_from_cache(fn cache -> cache[impl] end) || refresh_access_token!(impl) ||
        oauth_tokens!(impl)

    access_token
  end

  def refresh_access_token!(impl) do
    refresh_token =
      get_from_cache(fn cache -> cache[impl] end) || impl.get_refresh_token_from_env()

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

    store_in_cache(fn cache -> Map.put(cache, impl, tokens) end)

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

  defp get_from_cache(get_fn) do
    Agent.get(agent(), get_fn)
  end

  defp store_in_cache(update_fn) do
    Agent.update(agent(), update_fn)
  end

  # Use a local agent as a cache system
  defp agent() do
    case Agent.start_link(fn -> %{} end, name: __MODULE__) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end
end
