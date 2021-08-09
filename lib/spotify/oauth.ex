defmodule Spotify.OAuth do
  use Tesla

  @behaviour OAuth

  @app_client_id Application.compile_env!(:roule_avec_spot, [Spotify, :client_id])
  @app_client_secret Application.compile_env!(:roule_avec_spot, [Spotify, :client_secret])
  @scopes ["playlist-modify-public", "ugc-image-upload", "playlist-modify-private"]
  @redirect_uri Application.compile_env!(:roule_avec_spot, [Spotify, :redirect_uri])

  def get_token() do
    token = read_token()

    cond do
      token ->
        token

      true ->
        token = OAuth.create_access_token!(Spotify.OAuth)
        store_token(token)
        token
    end
  end

  defp read_token() do
    Application.get_env(:roule_avec_spot, :spotify_access_token)
  end

  defp store_token(token) do
    Application.put_env(:roule_avec_spot, :spotify_access_token, token)
  end

  @impl OAuth
  def uri() do
    "https://accounts.spotify.com/authorize"
    |> URI.parse()
    |> Map.put(
      :query,
      URI.encode_query(%{
        "client_id" => @app_client_id,
        "response_type" => "code",
        "redirect_uri" => @redirect_uri,
        "scope" => Enum.join(@scopes, " ")
      })
    )
    |> URI.to_string()
  end

  @impl OAuth
  def exchange_code!({:spotify, code}) do
    %{"access_token" => token} =
      make_oauth_request(%{
        "code" => code,
        "grant_type" => "authorization_code",
        "redirect_uri" => @redirect_uri
      })

    token
  end

  defp make_oauth_request(request_params) do
    client =
      Tesla.client([
        Tesla.Middleware.FormUrlencoded
        # Tesla.Middleware.Logger
      ])

    authorization = "#{@app_client_id}:#{@app_client_secret}"

    %{status: 200, body: body} =
      post!(
        client,
        "https://accounts.spotify.com/api/token",
        request_params,
        headers: [{"Authorization", "Basic #{Base.encode64(authorization)}"}]
      )

    Jason.decode!(body)
  end

  defmodule Middleware do
    @behaviour Tesla.Middleware

    def call(env, next, _) do
      env
      |> Map.update!(:headers, &[{"Authorization", "Bearer #{Spotify.OAuth.get_token()}"} | &1])
      |> Tesla.run(next)
    end
  end
end
