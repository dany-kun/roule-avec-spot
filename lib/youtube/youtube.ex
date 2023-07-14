defmodule Youtube do
  use Tesla
  @base_url "https://www.googleapis.com/youtube/v3"

  plug(Tesla.Middleware.JSON)
  # plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.BaseUrl, @base_url)
  plug(Youtube.OAuth.Middleware)

  def get_channel_last_videos(channel_id) do
    %{status: 200, body: body} = fetch_videos(channel_id)
    %{"items" => items} = body

    videos =
      Enum.map(items, fn item ->
        %{
          video_id: item["id"]["videoId"],
          video_title: item["snippet"]["title"],
          published_time: DateTime.from_iso8601(item["snippet"]["publishedAt"])
        }
      end)

    # Only keep videos published the last 6 days
    now = DateTime.utc_now()
    last_videos = videos_after_timestamp(videos, DateTime.add(now, -6 * 24 * 3600, :second))

    case last_videos do
      [] ->
        {:error, :no_video}

      [last_video] ->
        {:ok, %{video: last_video}}

      [_last_video | _] ->
        {:ok, %{multiple_videos: last_videos}}
    end
  end

  defp fetch_videos(channel_id) do
    get!("/search",
      query: [
        channelId: channel_id,
        order: "date",
        type: "video",
        part: "snippet"
      ]
    )
  end

  defp videos_after_timestamp(videos, from_datetime) do
    Enum.filter(videos, fn item ->
      {:ok, video_published_time, 0} = item.published_time
      DateTime.compare(video_published_time, from_datetime) == :gt
    end)
  end

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
    [group | _] = Regex.run(~r/.*([1|•][-|.•\s?](?:.|\n)*)/, description)

    group
    |> String.split("\n")
    |> Stream.with_index()
    |> Enum.filter(fn {e, i} -> String.match?(e, ~r/#{i + 1}(-|.)/) end)
    |> Enum.map(fn {e, i} -> String.replace(e, ~r/#{i + 1}(-|.)/, "") end)
    |> Enum.map(fn e -> String.trim(e) end)
    |> Enum.filter(fn s -> s != "" end)
  end
end
