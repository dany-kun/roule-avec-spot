defmodule Youtube do
  use Tesla
  @base_url "https://www.googleapis.com/youtube/v3"

  plug(Tesla.Middleware.JSON)
  # plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.BaseUrl, @base_url)
  plug(Youtube.OAuth.Middleware)

  def get_channel_videos(channel_id) do
    %{status: 200, body: body} =
      get!("/search",
        query: [
          channelId: channel_id,
          order: "date",
          type: "video",
          part: "snippet"
        ]
      )

    %{"items" => items} = body

    now = DateTime.utc_now()
    # Only keep videos published the last 6 days
    find_last_videos(items, DateTime.add(now, -6 * 24 * 3600, :second)) |> last_video()
  end

  defp find_last_videos(videos, from_datetime) do
    videos
    |> Enum.map(fn item ->
      %{
        video_id: item["id"]["videoId"],
        video_title: item["snippet"]["title"],
        published_time: DateTime.from_iso8601(item["snippet"]["publishedAt"])
      }
    end)
    |> Enum.filter(fn item ->
      {:ok, video_published_time, 0} = item.published_time
      DateTime.compare(video_published_time, from_datetime) == :gt
    end)
  end

  defp last_video([]), do: {:err, "No video published this week"}
  defp last_video([video]), do: {:ok, video}

  defp last_video(videos),
    do: {:err, "Found multiple videos published last week, got #{length(videos)} videos", videos}

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
