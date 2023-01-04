defmodule Core do
  @my_spotify_user_id Application.compile_env!(:roule_avec_spot, [Spotify, :user_id])

  @channel_id Application.compile_env!(:roule_avec_spot, [Youtube, :channel_id])

  def create_playlist(), do: create_playlist(@channel_id)

  def create_playlist(channel_id) do
    case Youtube.get_channel_last_video(channel_id) do
      {:ok, %{video: video}} ->
        Line.send_text_message("A new video was published #{video.video_title}")
        create_playlist_from_video(video.video_id)

      {:error, :no_video} ->
        Line.send_text_message("No video was published")

      {:error, %{multiple_videos: videos}} ->
        videos = Enum.map_join(videos, ", ", fn v -> v.video_title end)

        Line.send_text_message("Several videos were published #{videos}")
    end
  end

  def create_playlist_from_video(video_id, playlist_name \\ nil) do
    details = get_video_info(video_id)

    uris =
      case details.uris do
        %{err: err} ->
          raise(err)

        %{ok: uri_detailed} ->
          uri_detailed
          |> IO.inspect()
          |> Enum.map(fn e -> e[:uri] end)
      end

    playlist_name = playlist_name || sanitize_video_title(details.title)

    create_playlist_from_uris(playlist_name, uris, details)
  end

  defp sanitize_video_title(video_title) do
    String.replace(video_title, ["Roule avec Driver", "spécial"], "")
    |> String.replace(~r/\s+/, " ")
  end

  def create_playlist_from_uris(playlist_name, uris, info) do
    id = Spotify.create_playlist(@my_spotify_user_id, playlist_name, info)
    # TODO: store in DB
    Spotify.update_playlist_tracks(id, uris)
    IO.puts("Created playlist #{playlist_name} : #{id}")
    Line.send_text_message("A new playlist was created #{playlist_name}")
  end

  def get_video_info(video_id) do
    %{description: tracks, link: link, title: title} = Youtube.get_video_info(video_id)

    uris =
      Enum.map(tracks, fn track -> Spotify.find_track(track) end)
      |> Enum.filter(fn track -> track end)
      |> Enum.group_by(fn e -> elem(e, 0) end, fn e -> elem(e, 1) end)

    %{uris: uris, link: link, title: title}
  end
end
