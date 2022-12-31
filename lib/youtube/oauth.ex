defmodule Youtube.OAuth do
  use Tesla

  @behaviour OAuth.AuthorizationCode
  @base_url "https://accounts.google.com/o/oauth2/v2/auth"
  @client_id Application.compile_env(:roule_avec_spot, [Youtube, :client_id])
  @client_secret Application.compile_env(:roule_avec_spot, [Youtube, :client_secret])
  @redirect_uri Application.compile_env(:roule_avec_spot, [Youtube, :redirect_uri])
  @api_key Application.compile_env(:roule_avec_spot, [Youtube, :api_key])

  def api_key() do
    @api_key
  end

  def get_token() do
    token = read_token()

    cond do
      token ->
        token

      true ->
        token = OAuth.AuthorizationCode.create_access_token!(Youtube.OAuth)
        Application.put_env(:roule_avec_spot, :google_token, token)
        token
    end
  end

  def read_token() do
    Application.get_env(:roule_avec_spot, :google_token)
  end

  @impl OAuth.AuthorizationCode
  def exchange_code!({:youtube, code}) do
    client =
      Tesla.client([
        Tesla.Middleware.FormUrlencoded
        # Tesla.Middleware.Logger
      ])

    %{status: 200, body: body} =
      post!(client, "https://oauth2.googleapis.com/token", %{
        "client_id" => @client_id,
        "client_secret" => @client_secret,
        "redirect_uri" => @redirect_uri,
        "code" => code,
        "grant_type" => "authorization_code"
      })

    %{"access_token" => token} = Jason.decode!(body)
    token
  end

  @impl OAuth.AuthorizationCode
  def uri() do
    query =
      URI.encode_query(%{
        "client_id" => @client_id,
        "redirect_uri" => @redirect_uri,
        "response_type" => "code",
        "scope" => Enum.join(["https://www.googleapis.com/auth/youtube.readonly"], " ")
      })

    "#{@base_url}?#{query}"
  end

  defmodule Middleware do
    @behaviour Tesla.Middleware

    @authorization_grant Application.compile_env(
                           :roule_avec_spot,
                           [Youtube, :authorization_grant],
                           :code
                         )

    def call(env, next, _) do
      case @authorization_grant do
        :api_key ->
          env
          |> Map.update!(:query, &[{"key", Youtube.OAuth.api_key()} | &1])
          |> Tesla.run(next)

        :code ->
          env
          |> Map.update!(
            :headers,
            &[{"Authorization", "Bearer #{Youtube.OAuth.get_token()}"} | &1]
          )
          |> Tesla.run(next)
      end
    end
  end
end
