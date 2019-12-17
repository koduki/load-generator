defmodule App.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, arg, _} =
      args
      |> OptionParser.parse(switches: [
        unum: :integer,
        duration: :integer
      ])

    {opts, List.to_string(arg)}
  end

  defp response({opts, arg}) do
    users_num = if opts[:unum], do: opts[:unum], else: 1
    duration = if opts[:duration], do: opts[:duration], else: 1

    LoadGenerator.App.run(users_num, duration)
  end
end
