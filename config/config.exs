import Config

case config_env() do
  :dev ->
    import_config(".dev.secrets.exs")

  :prod ->
    import_config("prod.config.exs")
end
