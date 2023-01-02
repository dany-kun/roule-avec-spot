import Config

config :roule_avec_spot, Youtube,
  client_secret: System.get_env("YOUTUBE_OAUTH_CLIENT_SECRET"),
  client_id: System.get_env("YOUTUBE_OAUTH_CLIENT_ID"),
  redirect_uri: System.get_env("YOUTUBE_OAUTH_CLIENT_REDIRECT_URI"),
  channel_id: System.get_env("YOUTUBE_CHANNEL_ID")

config :roule_avec_spot, Spotify,
  client_secret: System.get_env("SPOTIFY_OAUTH_CLIENT_SECRET"),
  client_id: System.get_env("SPOTIFY_OAUTH_CLIENT_ID"),
  redirect_uri: System.get_env("SPOTIFY_OAUTH_CLIENT_REDIRECT_URI"),
  user_id: System.get_env("SPOTIFY_USER_ID")
