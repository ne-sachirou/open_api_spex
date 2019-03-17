defmodule OpenApiSpex.Plug.CastTest do
  use ExUnit.Case

  describe "query params - basics" do
    test "Valid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=true")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end

    test "Invalid value" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 422
    end

    test "Invalid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=123&inValidParam=123&inValid2=hi")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 422
      assert conn.resp_body == "Undefined query parameter: \"inValid2\""
    end

    test "with requestBody" do
      body =
        Poison.encode!(%{
          phone_number: "123-456-789",
          postal_address: "123 Lane St"
        })

      conn =
        :post
        |> Plug.Test.conn("/api/users/123/contact_info", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end

    test "opts[:compat_params?]" do
      conn =
        :get
        |> Plug.Test.conn("/api/cast_with_compat_params/?validParam=true")
        |> OpenApiSpexTest.Router.call([])

      assert conn.query_params == %{"validParam" => "true"}
      assert conn.params == %{validParam: true}
      assert conn.status == 200

      conn =
        :get
        |> Plug.Test.conn("/api/cast_with_compat_params/123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.path_params == %{"id" => "123"}
      assert conn.params == %{id: 123}
      assert conn.status == 200

      body =
        Poison.encode!(%{
        "user" => %{
          "name" => "Joe User",
          "email" => "joe@gmail.com"
        }
      })

      conn =
        :patch
        |> Plug.Test.conn("/api/cast_with_compat_params/123", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      IO.inspect Map.take(conn, conn |> Map.keys |> Enum.filter(&(&1 |> to_string |> String.ends_with?("params"))))
      IO.inspect Map.take(conn, conn |> Map.keys |> Enum.filter(&(&1 |> to_string |> String.starts_with?("resp"))))
      # assert conn.path_params == %{"id" => "123"}
      # assert conn.params == %{id: 123}
      assert conn.body_params == %OpenApiSpexTest.Schemas.UserRequest{user: %OpenApiSpexTest.Schemas.User{name: "Joe User", email: "joe@gmail.com"}}
      assert conn.status == 200
    end
  end

  describe "query params - param with custom error handling" do
    test "Valid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=true")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end

    test "Invalid value" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400
    end

    test "Invalid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=123&inValidParam=123&inValid2=hi")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400
      assert conn.resp_body == "Undefined query parameter: \"inValid2\""
    end
  end

  describe "body params" do
    test "Valid Request" do
      request_body = %{
        "user" => %{
          "id" => 123,
          "name" => "asdf",
          "email" => "foo@bar.com",
          "updated_at" => "2017-09-12T14:44:55Z"
        }
      }

      conn =
        :post
        |> Plug.Test.conn("/api/users", Poison.encode!(request_body))
        |> Plug.Conn.put_req_header("content-type", "application/json; charset=UTF-8")
        |> OpenApiSpexTest.Router.call([])

      assert conn.body_params == %OpenApiSpexTest.Schemas.UserRequest{
               user: %OpenApiSpexTest.Schemas.User{
                 id: 123,
                 name: "asdf",
                 email: "foo@bar.com",
                 updated_at: ~N[2017-09-12T14:44:55Z] |> DateTime.from_naive!("Etc/UTC")
               }
             }

      assert Poison.decode!(conn.resp_body) == %{
               "data" => %{
                 "email" => "foo@bar.com",
                 "id" => 1234,
                 "inserted_at" => nil,
                 "name" => "asdf",
                 "updated_at" => "2017-09-12T14:44:55Z"
               }
             }
    end

    test "Invalid Request" do
      request_body = %{
        "user" => %{
          "id" => 123,
          "name" => "*1234",
          "email" => "foo@bar.com",
          "updated_at" => "2017-09-12T14:44:55Z"
        }
      }

      conn =
        :post
        |> Plug.Test.conn("/api/users", Poison.encode!(request_body))
        |> Plug.Conn.put_req_header("content-type", "application/json")

      conn = OpenApiSpexTest.Router.call(conn, [])
      assert conn.status == 422

      assert conn.resp_body ==
               "#/user/name: Value \"*1234\" does not match pattern: [a-zA-Z][a-zA-Z0-9_]+"
    end
  end
end
