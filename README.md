Generate Spotify playlists from Roule Avec Driver Youtube videos description.

https://www.youtube.com/channel/UCNPuaSjy7yu0WcNIFYi9FIg

All credits to Driver.

## Setup

This project use 2 wep APIs: Youtube and Spotify

### Youtube

`:roule_avec_spot, Youtube, :client_secret`, `:roule_avec_spot, Youtube, :client_id`,
`:roule_avec_spot, Youtube, :redirect_uri` must be set as mix environment variables

### Spotify

`:roule_avec_spot, Spotify, :user_id` (the spotify user id to creating the Spotify playlists), `:roule_avec_spot, Spotify, :client_secret`, `:roule_avec_spot, Spotify, :client_id`,
`:roule_avec_spot, Spotify, :redirect_uri` must be set as mix environment variables

## Usage

`App.main("video_id", "playlist_name")` with `video_id` being the Youtube "Roule avec driver" video id to generate the playlist from (playlist generally included in the video description) and `playlist_name` being used in the generated Spotify playlist name like "Roule avec Driver - #{playlist_name}".
