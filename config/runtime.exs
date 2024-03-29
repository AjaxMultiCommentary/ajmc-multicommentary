import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# Start the phoenix server if environment is set and running in a release
if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :text_server, TextServerWeb.Endpoint, server: true
end

config :text_server,
  enable_api: config_env() == :dev or System.get_env("ENABLE_AJMC_API") == "true",
  env: config_env(),
  iiif_root_url: System.get_env("IIIF_ROOT_URL", "/iiif/"),
  strip_port_from_urls: config_env() == :prod

config :ex_aws,
  access_key_id: System.get_env("S3_ACCESS_KEY", ""),
  secret_access_key: System.get_env("S3_SECRET_KEY", "")

config :ex_aws, :s3,
  scheme: "#{System.get_env("S3_SCHEME", "")}://",
  host: System.get_env("S3_HOST", ""),
  port: System.get_env("S3_PORT", "")

config :text_server, GitHub.API,
  base_url:
    System.get_env(
      "GITHUB_API_URL",
      "https://api.github.com/repos/ajaxmulticommentary/commentaries_data"
    ),
  token: System.get_env("GITHUB_API_TOKEN")

config :text_server, Zotero.API,
  base_url: System.get_env("ZOTERO_API_URL"),
  token: System.get_env("ZOTERO_API_TOKEN")

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :text_server, TextServer.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST", "ajmc.unil.ch")
  port = String.to_integer(System.get_env("PORT", "4000"))

  config :text_server, TextServerWeb.Endpoint,
    url: [host: host, port: port],
    http: [
      ip: {0, 0, 0, 0},
      port: port
    ],
    check_origin: false,
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :text_server, TextServerWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  config :text_server, TextServer.Mailer,
    adapter: Swoosh.Adapters.Sendgrid,
    api_key: System.get_env("SENDGRID_API_KEY"),
    domain: "localhost"

  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:

  config :swoosh, :api_client, Swoosh.ApiClient.Hackney

  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
