defmodule Line do
  use Tesla

  @base_url "https://api.line.me/v2"

  plug(Tesla.Middleware.BaseUrl, @base_url)
  plug(Tesla.Middleware.JSON)
  # plug(Tesla.Middleware.Logger, debug: false, filter_headers: ["Authorization"])
  plug(Line.OAuth.Middleware)

  def send_text_message(message) do
    %{status: 200} =
      post!("/bot/message/broadcast", %{
        "messages" => [
          %{
            "type" => "text",
            "text" => message
          }
        ]
      })
  end
end
