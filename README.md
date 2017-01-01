# Überauth Buffer

> Buffer OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [Buffer Developers](https://buffer.com/developers/apps/create).

1. Add `:ueberauth_buffer` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_buffer, "~> 0.0.1"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_buffer]]
    end
    ```

1. Add Buffer to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        buffer: {Ueberauth.Strategy.Buffer, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Buffer.OAuth,
      client_id: System.get_env("BUFFER_CLIENT_ID"),
      client_secret: System.get_env("BUFFER_CLIENT_SECRET"),
      access_token: System.get_env("BUFFER_ACCESS_TOKEN")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/buffer

## License

Please see [LICENSE](https://github.com/pineconellc/ueberauth_buffer/blob/master/LICENSE) for licensing details.
