defmodule App do
  @my_spotify_user_id Application.compile_env!(:roule_avec_spot, [Spotify, :user_id])
  @channel_id Application.compile_env!(:roule_avec_spot, [Youtube, :channel_id])

  def create_playlist(), do: create_playlist(@channel_id)

  def create_playlist(channel_id) do
    {:ok, video} = Youtube.get_channel_videos(channel_id)
    create_playlist_from_video(video.video_id, nil)
  end

  def create_playlist_from_video(video_id, playlist_name) do
    details = get_track_uris(video_id)

    uris =
      case details.uris do
        %{err: err} ->
          raise(err)

        %{ok: uri_detailed} ->
          uri_detailed
          |> IO.inspect()
          |> Enum.map(fn e -> e[:uri] end)
      end

    create_playlist_from_uris(playlist_name, uris, details)
  end

  def create_playlist_from_uris(playlist_name, uris, info) do
    id = Spotify.create_playlist(@my_spotify_user_id, playlist_name, info)
    # TODO: store in DB
    Spotify.update_playlist_tracks(id, uris)
    IO.puts("Created playlist #{playlist_name} : #{id}")
  end

  def get_track_uris(video_id) do
    %{description: tracks, link: link, title: title} = Youtube.get_video_info(video_id)

    uris =
      Enum.map(tracks, fn track -> Spotify.find_track(track) end)
      |> Enum.filter(fn track -> track end)
      |> Enum.group_by(fn e -> elem(e, 0) end, fn e -> elem(e, 1) end)

    %{uris: uris, link: link, title: title}
  end
end
