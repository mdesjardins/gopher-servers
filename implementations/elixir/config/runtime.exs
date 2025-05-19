import Config

config :gopher_server, :port, System.get_env("PORT", "70")
config :gopher_server, :host, System.get_env("HOST", "localhost")
config :gopher_server, :root, System.get_env("ROOT", "/var/gopher")
config :gopher_server, :mapfile, System.get_env("GOPHERMAP", "gophermap")
