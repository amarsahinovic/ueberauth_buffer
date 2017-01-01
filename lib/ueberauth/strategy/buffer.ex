defmodule Ueberauth.Strategy.Buffer do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Buffer.
  """
  use Ueberauth.Strategy, uid_field: :id,
                          default_scope: "",
                          oauth2_module: Ueberauth.Strategy.Buffer.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the Buffer authentication page.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [redirect_uri: callback_url(conn), scope: scopes]

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Buffer. When there is a failure from Buffer the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Buffer is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{ params: %{ "code" => code } } = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code, redirect_uri: callback_url(conn)]])

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Buffer response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:buffer_user, nil)
    |> put_private(:buffer_token, nil)
  end

  @doc """
  Fetches the uid field from the Buffer response. This defaults to the option `uid_field` which in-turn defaults to `login`
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.buffer_user[uid_field]
  end

  @doc """
  Includes the credentials from the Buffer response.
  """
  def credentials(conn) do
    token = conn.private.buffer_token
    scopes =
      token.other_params["scope"] || ""
      |> String.split(",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Buffer callback.
  """
  def extra(conn) do
    %Extra {
      raw_info: %{
        token: conn.private.buffer_token,
        user: conn.private.buffer_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :buffer_token, token)
    # Will be better with Elixir 1.3 with/else
    case Ueberauth.Strategy.Buffer.OAuth.get(token, "user.json") do
      { :ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      { :ok, %OAuth2.Response{status_code: 404, body: body}} ->
        set_errors!(conn, [error("token", body["error"])])

      { :ok, %OAuth2.Response{status_code: status_code, body: user} } when status_code in 200..399 ->
        put_private(conn, :buffer_user, user)

      { :error, %OAuth2.Error{reason: reason} } ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
