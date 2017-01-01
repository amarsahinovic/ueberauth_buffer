defmodule Ueberauth.Strategy.Buffer.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Buffer.

  To add your `client_id`, `client_secret` and `access_token` include these values in your configuration.

      config :ueberauth, Ueberauth.Strategy.Buffer.OAuth,
        client_id: System.get_env("BUFFER_CLIENT_ID"),
        client_secret: System.get_env("BUFFER_CLIENT_SECRET"),
        access_token: System.get_env("BUFFER_ACCESS_TOKEN")
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://api.bufferapp.com/1/",
    authorize_url: "https://bufferapp.com/oauth2/authorize",
    token_url: "https://api.bufferapp.com/1/oauth2/token.json",
  ]

  @doc """
  Construct a client for requests to Buffer.

  This will be setup automatically for you in `Ueberauth.Strategy.Buffer`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    opts = Keyword.merge(@defaults, Application.get_env(:ueberauth, Ueberauth.Strategy.Buffer.OAuth))
    |> Keyword.merge(opts)

    OAuth2.Client.new(opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    client(opts)
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    client([token: token])
    |> put_param("access_token", token.access_token)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_token!(params \\ [], options \\ []) do
    headers = Keyword.get(options, :headers, [])
    options = Keyword.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, [])
    client = OAuth2.Client.get_token!(client(client_options), params, headers, options)
    client.token
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("code", Keyword.get(params, :code))
    |> put_param("client_id", client.client_id)
    |> put_param("client_secret", client.client_secret)
    |> put_param("grant_type", "authorization_code")
    |> put_param("redirect_uri", Keyword.get(params, :redirect_uri))
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
