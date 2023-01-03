defmodule Youtube.OAuth do
  use Tesla

  @behaviour OAuth
  @base_url "https://accounts.google.com/o/oauth2/v2/auth"
  @client_id Application.compile_env!(:roule_avec_spot, [Youtube, :client_id])
  @client_secret Application.compile_env!(:roule_avec_spot, [Youtube, :client_secret])
  @redirect_uri Application.compile_env(:roule_avec_spot, [Youtube, :redirect_uri])
  @refresh_token Application.compile_env(:roule_avec_spot, [Youtube, :refresh_token])

  def access_token!() do
    OAuth.access_token!(Youtube.OAuth)
  end

  @impl OAuth
  def get_refresh_token_from_env() do
    @refresh_token
  end

  @impl OAuth
  def refresh_access_token!(refresh_token) do
    %{"access_token" => access_token} =
      make_oauth_request(%{
        "client_id" => @client_id,
        "client_secret" => @client_secret,
        "refresh_token" => refresh_token,
        "grant_type" => "refresh_token"
      })

    %{access_token: access_token}
  end

  @impl OAuth
  def exchange_code!({:youtube, code}) do
    %{"access_token" => access_token, "refresh_token" => refresh_token} =
      make_oauth_request(%{
        "client_id" => @client_id,
        "client_secret" => @client_secret,
        "redirect_uri" => @redirect_uri,
        "code" => code,
        "grant_type" => "authorization_code"
      })

    %{access_token: access_token, refresh_token: refresh_token}
  end

  defp make_oauth_request(params) do
    client =
      Tesla.client([
        Tesla.Middleware.FormUrlencoded
        # Tesla.Middleware.Logger
      ])

    %{status: 200, body: body} = post!(client, "https://oauth2.googleapis.com/token", params)

    Jason.decode!(body)
  end

  @impl OAuth
  def uri() do
    query =
      URI.encode_query(%{
        "client_id" => @client_id,
        "redirect_uri" => @redirect_uri,
        "response_type" => "code",
        "access_type" => "offline",
        "prompt" => "consent",
        "scope" => Enum.join(["https://www.googleapis.com/auth/youtube.readonly"], " ")
      })

    "#{@base_url}?#{query}"
  end

  defmodule Middleware do
    @behaviour Tesla.Middleware

    def call(env, next, _) do
      env
      |> Map.update!(
        :headers,
        &[{"Authorization", "Bearer #{Youtube.OAuth.access_token!()}"} | &1]
      )
      |> Tesla.run(next)
    end
  end
end
