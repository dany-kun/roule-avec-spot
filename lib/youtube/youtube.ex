defmodule Youtube do
  use Tesla
  @base_url "https://www.googleapis.com/youtube/v3"

  plug(Tesla.Middleware.JSON)
  # plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.BaseUrl, @base_url)
  plug(Youtube.OAuth.Middleware)

  def get_video_info(video_id) do
    %{status: 200, body: body} =
      get!("/videos", query: [id: video_id, part: "snippet,contentDetails,statistics"])

    %{"items" => [%{"snippet" => snippet} | _]} = body
    %{"description" => description, "title" => title} = snippet

    %{
      description: parse_description(description),
      link: "https://www.youtube.com/watch?v=#{video_id}",
      title: title
    }
  end

  defp parse_description(description) do
    [group | _] = Regex.run(~r/.*(1[-|.•](?:.|\n)*)/, description)

    group
    |> String.split("\n")
    |> Stream.with_index()
    |> Enum.filter(fn {e, i} -> String.match?(e, ~r/#{i + 1}(-|.)/) end)
    |> Enum.map(fn {e, i} -> String.replace(e, ~r/#{i + 1}(-|.)/, "") end)
    |> Enum.map(fn e -> String.trim(e) end)
    |> Enum.filter(fn s -> s != "" end)
  end
end
