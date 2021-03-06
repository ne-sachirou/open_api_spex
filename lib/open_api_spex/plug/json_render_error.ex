defmodule OpenApiSpex.Plug.JsonRenderError do
  @behaviour Plug

  alias Plug.Conn
  alias OpenApiSpex.OpenApi

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, errors) when is_list(errors) do
    response = %{
      errors: Enum.map(errors, &render_error/1)
    }

    json = OpenApi.json_encoder().encode!(response)

    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(422, json)
  end

  def call(conn, reason) do
    call(conn, [reason])
  end

  defp render_error(error) do
    path = error.path |> Enum.map(&to_string/1) |> Path.join()
    pointer = "/" <> path

    %{
      title: "Invalid value",
      source: %{
        pointer: pointer
      },
      message: to_string(error)
    }
  end
end
