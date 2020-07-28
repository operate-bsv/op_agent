defmodule MockServer do
  use Plug.Router
  plug Plug.Parsers, [
    parsers: [:json],
    pass:  ["text/*"],
    json_decoder: Jason
  ]
  plug :match
  plug :dispatch

  # Bitbus mock
  post "/block" do
    with ["test"] <- get_req_header(conn, "token") do
      body = case conn.body_params do
        %{"q" => %{"find" => %{"tx.h" => _}}} ->
          File.read!("test/mocks/bitbus_fetch_tx.jsonnd")
        %{"q" => %{"find" => %{"out.tape.cell" => _}}} ->
          File.read!("test/mocks/bitbus_fetch_tx_by.jsonnd")
      end
      stream_resp(conn, 200, body)
    else
      _ ->
        stream_resp(conn, 403, File.read!("test/mocks/terminus_unauthorized.json"))
    end
  end


  # Bitsocket mock
  post "crawl" do
    with ["test"] <- get_req_header(conn, "token") do
      body = case conn.body_params do
        %{"q" => %{"find" => %{"tx.h" => _}}} ->
          File.read!("test/mocks/bitsocket_fetch_tx.jsonnd")
        %{"q" => %{"find" => %{"out.tape.cell" => _}}} ->
          File.read!("test/mocks/bitsocket_fetch_tx_by.jsonnd")
      end
      stream_resp(conn, 200, body)
    else
      _ ->
        stream_resp(conn, 403, File.read!("test/mocks/terminus_unauthorized.json"))
    end
  end


  # Setup the streaming response
  defp stream_resp(conn, status, body) do
    conn
    |> put_resp_header("content-length", Integer.to_string(byte_size(body)))
    |> send_chunked(status)
    |> stream_chunks(body)
  end

  # Breakup and stream the body in chunks
  defp stream_chunks(conn, body) when is_binary(body) do
    chunks = Regex.scan(~r/.{1,192}/s, body)
    |> Enum.map(&Enum.join/1)
    |> Kernel.++(["\n"])
    stream_chunks(conn, chunks)
  end
  defp stream_chunks(conn, []), do: conn
  defp stream_chunks(conn, [head | tail]) do
    case chunk(conn, head) do
      {:ok, conn} -> stream_chunks(conn, tail)
      {:error, :closed} -> conn
    end
  end

end
