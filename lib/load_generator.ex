defmodule LoadGenerator.App do
  import AssertionHelper
  import RestHelper
  import LoadTestHelper
  import LogHelper
  use Timex

  def run(users_num, duration) do
    test_id = UUID.uuid4(:hex)
    base_url = System.get_env("APP_BASE_URL")

    IO.puts "test id: #{test_id}, users_num: #{users_num}, duration: #{duration}"
    log(%{type: "test_info", test_id: test_id, users_num: users_num, duration: duration})

    merchant_ids = [
      req_create_merchant(base_url, test_id),
      req_create_merchant(base_url, test_id)
    ]
    IO.puts "merchant id: #{merchant_ids}"

    r1 = parallel(users_num, fn -> continue(duration, run_user(base_url, test_id, merchant_ids)) end)
    r2 = parallel(1, fn -> continue(duration, run_merchant(base_url, test_id, merchant_ids)) end)

    wait(r1)
    wait(r2)

    IO.puts "finished: #{test_id}"
  end

  def run_merchant(base_url, test_id, merchant_ids) do
    fn ->
      :timer.sleep(:rand.uniform(10_000))

      usedMonth = Timex.format!(Timex.now, "%Y%m", :strftime)
      req_merchant_summary(base_url, test_id, rand_select(merchant_ids), usedMonth)
    end
  end

  def run_user(base_url, test_id, merchant_ids) do
    fn ->
      account_no = req_origination(base_url, test_id)
      it("validate accountNo", [
        assertUniq(account_no)
      ])

      # run test senario
      loop_count = :rand.uniform(5)
      log(%{type: "loop count", test_id: test_id, loop_count: loop_count})
      senario001(base_url, test_id, account_no, merchant_ids, 0, 0, loop_count)
    end
  end

  def senario001(__base_url, _test_id, _account_no, _merchant_ids, _count, _sum, loop_count) when loop_count == 0 do
    []
  end

  def senario001(base_url, test_id, account_no, merchant_ids, count, sum, loop_count) do
    datetime = Timex.now

    # pay
    amount1 = :rand.uniform(100_000)
    _tid1 = req_authorize(base_url, test_id, account_no, rand_select(merchant_ids), amount1, datetime)

    amount2 = :rand.uniform(10_000)
    _tid2 = req_authorize(base_url, test_id, account_no, rand_select(merchant_ids), amount2, datetime)

    prevMonthDate = Timex.shift(datetime, months: -1)
    _tid3 = req_authorize(base_url, test_id, account_no, rand_select(merchant_ids), 1000, prevMonthDate)

    # show summary
    usedMonth = Timex.format!(datetime, "%Y%m", :strftime)
    body = req_summary(base_url, test_id, account_no, usedMonth)

    count = count + 2
    sum = sum + amount1 + amount2

    # validate
    assert = assert_template(body)
    it("validate transaction summary", [
      assert.("accountNo", :should_be, account_no),
      assert.("count", :should_be, count),
      assert.("summary", :should_be, sum)
    ])

    interval = :rand.uniform(2000)
    :timer.sleep(interval)

    senario001(base_url, test_id, account_no, merchant_ids, count, sum, loop_count - 1)
  end

  def req_create_merchant(base_url, test_id) do
    {:http_ok, body} = post(test_id, "#{base_url}/merchant/create", [])
    body["merchantId"]
  end

  def req_merchant_summary(base_url, test_id, merchant_id, usedMonth) do
    {:http_ok, body} = get(test_id, "#{base_url}/merchant/#{merchant_id}/summary/#{usedMonth}", [])
    body
  end

  def req_origination(base_url, test_id) do
    {:http_ok, body} = post(test_id, "#{base_url}/account/create", [])
    body["accountNo"]
  end

  def req_authorize(base_url, test_id, account_no, merchant_id, amount, usedDateTime) do
    req = Jason.encode!(%{"accountNo" => account_no, "merchantId" => merchant_id, "amount" => amount, "usedDateTime" => usedDateTime })
    {:http_ok, body} = post(test_id, "#{base_url}/payment/pay", req)

    body["transactionId"]
  end

  def req_summary(base_url, test_id, account_no, usedMonth) do
    {:http_ok, body} = get(test_id, "#{base_url}/account/#{account_no}/summary/#{usedMonth}", [])
    body
  end
end
