# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :dice_town, DiceTownWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "YtBqQDnLppBa8MmCRi54TW0BD7+DZyq2crL3k3kcOU5gDhf4p6B9g5wDDB2LX+cf",
  render_errors: [view: DiceTownWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: DiceTown.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
