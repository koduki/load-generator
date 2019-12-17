defmodule LogHelper do
  def log(message) do
    log_type = System.get_env("LOG_TYPE")
    if log_type == "GCP" do
      Task.async(fn -> publish2gcp(message) end)
    else
      Task.async(fn -> expot2file(message) end)
    end

  end

  def expot2file(message) do
    require Logger
    m = Jason.encode!(message)
    Logger.info("#{m}")
  end

  def publish2gcp(message) do
    project_id="koduki-docker-test-001-1083"
    topic_name="first-topic"

    m = Jason.encode!(message)

    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    conn = GoogleApi.PubSub.V1.Connection.new(token.token)

    # Build the PublishRequest struct
    request = %GoogleApi.PubSub.V1.Model.PublishRequest{
        messages: [
            %GoogleApi.PubSub.V1.Model.PubsubMessage{
                data: Base.encode64(m)
            }
        ]
    }

    r = GoogleApi.PubSub.V1.Api.Projects.pubsub_projects_topics_publish(
        conn,
        project_id,
        topic_name,
        [body: request]
    )
    case r do
      {:ok, response} -> response #IO.puts "published message #{response.messageIds}"
      {:error, msg} -> IO.puts "published message #{msg}"
    end

  end
end

defmodule LoadTestHelper do
  import LogHelper

  def rand_select(ids) do
    index =  (:rand.uniform(Enum.count(ids)) - 1)
    Enum.at(ids, index)
  end

  def parallel(num, callback) do
    Enum.map(1..num, fn(_) -> Task.async(fn -> callback.() end)end)
  end

  def wait(tasks) do
    tasks |> Enum.map(fn(task) -> Task.await(task, 1_000_000) end)
          |> List.flatten
  end

  def continue(duration, start_time \\ 0, end_time \\ 0, callback) do
    cond do
      start_time == 0 and end_time == 0 ->
        log(%{type: "continue_start", message: "PROCESS: START"})
        continue(duration, :os.system_time(:millisecond), :os.system_time(:millisecond), callback)
      (end_time - start_time) > duration * 1000  ->
        log(%{type: "continue_end", message: "PROCESS: END"})
        []
      true ->
        r = callback.()

        log(%{type: "continue_exec", elapsed_time: (end_time - start_time) / 1000 })
        [r] ++ continue(duration, start_time, :os.system_time(:millisecond), callback)
    end
  end
end

defmodule AssertionHelper do
  defmodule AssertionError do
    defexception [:message]
  end

  def assert_template(r) do
    fn (key, _operation, expectation) ->
      condition = (r[key] == expectation)
      if !condition do
        raise AssertionError, message: "#{key} should be #{expectation}"
      end
    end
  end

  def assertUniq(value) do
    if false do
      raise AssertionError, message: "#{value} should be uniq"
    end
  end

  def it(_title, _actuals) do

  end
end

defmodule RestHelper do
  import LogHelper

  def get(test_id, url, req) do
    {_,s} = DateTime.now("Etc/UTC")
    {t, r} = :timer.tc(fn ->
      case HTTPoison.get(url, req, []) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:http_ok, Jason.decode!(body)}
        _ -> {:error, nil}
      end
    end)
    {_,e} = DateTime.now("Etc/UTC")
    msg = %{type: "request", test_id: test_id, http_status: elem(r, 0), url: url, method: :get, response: t, start_time: s, end_time: e}
    log(msg)

    case r do
      {:http_ok, _} -> r
      {:http_error, _} -> exit :http_error
    end
  end

  def post(test_id, url, req) do
    {_,s} = DateTime.now("Etc/UTC")
    {t, r} = :timer.tc(fn ->
      case HTTPoison.post(url, req, [{"Content-Type", "application/json"}]) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:http_ok, Jason.decode!(body)}
        _ -> {:http_error, nil}
      end
    end)
    {_,e} = DateTime.now("Etc/UTC")

    msg = %{type: "request", test_id: test_id, http_status: elem(r, 0), url: url, method: :post, response: t, start_time: s, end_time: e}
    log(msg)

    case r do
      {:http_ok, _} -> r
      {:http_error, _} -> exit :http_error
    end
  end
end
