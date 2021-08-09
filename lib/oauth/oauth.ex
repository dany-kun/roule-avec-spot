defmodule OAuth do
  @doc "Define the uri the user must log to"
  @callback uri :: String.t()

  @doc "Exchange a oauth code for an access token"
  @callback exchange_code!({atom(), String.t()}) :: String.t()

  def create_access_token!(impl) do
    uri = impl.uri()
    code = get_code!(uri)
    impl.exchange_code!(code)
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
