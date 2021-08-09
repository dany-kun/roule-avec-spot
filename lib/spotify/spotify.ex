defmodule Spotify do
  use Tesla

  @base_url "https://api.spotify.com/v1"

  plug(Tesla.Middleware.BaseUrl, @base_url)
  plug(Tesla.Middleware.JSON)
  # plug(Tesla.Middleware.Logger, debug: false, filter_headers: ["Authorization"])
  plug(Spotify.OAuth.Middleware)

  def find_track(query, opts \\ [limit: 5, remove_featuring: true]) do
    sanitized = sanitize_search(query, opts[:remove_featuring])

    if sanitized do
      get_track_uri(sanitized, query, opts)
    else
      IO.puts("Skipping #{query}")
      nil
    end
  end

  defp get_track_uri(sanitized, query, opts) do
    case get!("/search", query: [q: sanitized, type: "track"] ++ Keyword.take(opts, [:limit])) do
      %{status: 200, body: %{"tracks" => %{"items" => tracks}}} ->
        track =
          Enum.find(tracks, fn track ->
            name = track["name"]
            !String.contains?(name, ["Club Mix", "Karaoke"])
          end) || List.first(tracks)

        if track do
          {:ok,
           %{
             search: sanitized,
             original_query: query,
             uri: track["uri"],
             name: track["name"],
             artists: Enum.map(track["artists"], fn a -> a["name"] end)
           }}
        else
          {:err, %{search: sanitized, original_query: query, error: "Could not find any track"}}
        end

      err ->
        {:err, %{search: sanitized, original_query: query, error: err}}
    end
  end

  def create_playlist(user_id, name, info) do
    playlist = playlist(name, info)

    case post!("/users/#{user_id}/playlists", playlist) do
      %{status: status, body: body} when status in [200, 201] -> body["id"]
    end
  end

  defp playlist(playlist_name, info) do
    %{
      "name" => "Roule avec Driver - #{playlist_name}",
      "description" => description(info)
    }
  end

  def update_playlist_description(playlist_id, info) do
    put!("/playlists/#{playlist_id}", %{"description" => description(info)})
  end

  defp description(%{title: title, link: link}) do
    "Playlist generated from the Roule avec Driver youtube video \"#{title}\" [#{link}]. All credits to driver"
  end

  def update_playlist_tracks(playlist_id, tracks) do
    put!("/playlists/#{playlist_id}/tracks", %{"uris" => tracks})
  end

  def _update_playlist_image(_playlist_id, _image_uri) do
    # TODO
    # put!("/playlists/#{playlist_id}/images", )
  end

  def get_playlist(playlist_id) do
    get!("/playlists/#{playlist_id}")
  end

  def get_user() do
    get!("/me")
  end

  # Remove feat, ft. Feat...
  defp sanitize_search(query, remove_featuring) do
    if remove_featuring do
      String.replace(query, ~r/(\s+)[fF](ea)?t(.)?[^\\"]*/, " ")
    else
      String.replace(query, ~r/(\s+)[fF](ea)?t(.)?(\s+)/, "\\1")
    end
    |> String.replace(~r/(\s+)&?(\s+)/, " ")
    |> String.replace("\"", "")
    |> String.replace("(", "")
    |> String.replace(")", "")
    |> String.trim()
    |> manual_fixes()
  end

  defp manual_fixes(value) do
    Map.get(
      %{
        "The Game Busta Rhymes Doctor's advocate" => "The Game Doctor's advocate",
        "The Game Travis Barker dope boys" => "The Game dope boys",
        "The Game Snoop Dogg Xzibit California vacation :" => "The Game California vacation",
        "Lil Kim Angie Martinez, Lefteye, Da Brat Missy Elliott not tonight  ladies night" =>
          "Lil Kim Da Brat not tonight",
        "Lil Kim Jay-Z Lil Cease big momma thang" => "Lil Kim big momma thang",
        "Lil Kim Sisqo how many licks ?" => "Lil Kim Sisqo how many licks",
        "Total Da Brat, Lil Kim Foxy Brown" => "Total Da Brat no one else",
        "Dj Quik just lyke Compton" => "Dj Quik jus lyke Compton",
        "Dj Quik something 4 tha mood" => "Dj Quik somethin 4 tha mood",
        "Dj Quik down down down" => "Dj Quik amg down down down",
        # Ampersand to get part I and not part II ; weird spotify
        "Lloyd Banks  warriors" => "Lloyd Banks  warrior &",
        "BONE THUGS-N-HARMONY Ectasy" => "BONE THUGS-N-HARMONY Ecstasy",
        "Cypress Hill throw your set in the air remix ." =>
          "Cypress Hill throw your hands in the air",
        "Fat Joe samedi 2 say" => "Fat Joe safe 2 say",
        "Lil Jon The East Side Boyz  every freakin' night" => "Lil Jon every freakin' night",
        "Outkast southernplayerlisticadillacmuzik" => "Outkast southern",
        "The notorious B.I.G. ten crack commandements" => "The notorious B.I.G. ten crack",
        "Warren G game don't wait remix" => "Warren G game don't wait",
        "Warren G Let's get high" => nil
      },
      value,
      value
    )
  end
end
