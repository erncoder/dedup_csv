defmodule DedupCSV do
  @moduledoc """
  A CSV file of employee records can often include duplicated rows. This module
  provides a mechanism to remove all duplicated rows, keying off of selected
  field(s).
  """
  @compile if Mix.env() == :test, do: :export_all
  @strategies [:email, :phone, :email_or_phone]
  @file_size_coefficient 0.4

  require CSV
  require Logger

  @doc """
  Takes the path to an employee-record CSV file and a strategy and returns a new
  CSV that has removed _all_ duplicate rows, according to the strategy. The file
  is expected to have the headers "First Name", "Last Name", "Phone", and
  "Email". Empty fields are _ignored_ as unique-keying values.

  The resulting file is written to a time-stamped file located in the `output`
  subdirectory.
  """
  def run(file_path, strategy) when is_binary(file_path) and strategy in @strategies do
    if file_size_ok?(file_path) do
      {decoded, seens} =
        file_path
        |> File.stream!()
        |> CSV.decode(headers: true)
        |> Enum.map_reduce(%{"emails" => %{}, "phones" => %{}}, &mapper(&1, &2, strategy))

      decoded
      |> Enum.filter(&filter(&1, seens, strategy))
      |> write_to_csv(file_path)
    else
      msg = "file too large"
      Logger.error(msg)
      {:error, msg}
    end
  end

  def run(file_path, _strategy), do: {:error, "bad file path: #{inspect(file_path)}"}

  #
  # Secondary Functions
  #

  # This function builds out a list of all seen fields and records whether they
  # have been seen more than once. The stream has to be iterated over at least
  # once before any fields can be removed, so the filtration step has to be
  # broken out and performed afterward.
  defp mapper(decoded_tuple, acc, strategy)

  defp mapper({:ok, row}, acc, :email) do
    seen_emails = build_email_seens(row, acc)
    {row, %{acc | "emails" => seen_emails}}
  end

  defp mapper({:ok, row}, acc, :phone) do
    seen_phones = build_phone_seens(row, acc)
    {row, %{acc | "phones" => seen_phones}}
  end

  defp mapper({:ok, row}, acc, :email_or_phone) do
    seen_emails = build_email_seens(row, acc)
    seen_phones = build_phone_seens(row, acc)
    {row, %{acc | "emails" => seen_emails, "phones" => seen_phones}}
  end

  defp mapper({:error, _err}, acc, _strategy), do: {nil, acc}

  # This function filters out any rows that have been seen more than once, as
  # dictated by the specified strategy.
  defp filter(row, seen_keys, strategy)

  defp filter(%{"Email" => email}, %{"emails" => seen_emails}, :email),
    do: unique_item?(seen_emails, email)

  defp filter(%{"Phone" => phone}, %{"phones" => seen_phones}, :phone),
    do: unique_item?(seen_phones, phone)

  defp filter(
         %{"Email" => email, "Phone" => phone},
         %{"emails" => seen_emails, "phones" => seen_phones},
         :email_or_phone
       ),
       do: unique_item?(seen_emails, email) and unique_item?(seen_phones, phone)

  defp write_to_csv([], _) do
    msg = "empty or otherwise invalid CSV"
    Logger.error(msg)
    {:error, msg}
  end

  defp write_to_csv(list, file_path) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    filename = "output/#{Path.basename(file_path)}--deduped--#{now}.csv"
    headers = "First Name,Last Name,Email,Phone\n"

    body =
      list
      |> Enum.map(fn row ->
        [row["First Name"], row["Last Name"], row["Email"], row["Phone"]] |> Enum.join(",")
      end)
      |> Enum.join("\n")

    case File.write(filename, headers <> body) do
      :ok -> Logger.info("successfully wrote #{filename}")
      err -> Logger.error(IO.inspect(err))
    end
  end

  #
  # Tertiary Functions
  #

  defp build_email_seens(%{"Email" => email}, %{"emails" => emails}),
    do: build_seens(emails, email)

  defp build_phone_seens(%{"Phone" => phone}, %{"phones" => phones}),
    do: build_seens(phones, phone)

  # This function performs a double purpose: it writes first impressions to the
  # "seen" map, but also updates the "seen more than once" boolean, as required.
  defp build_seens(seen, key), do: Map.update(seen, key, false, fn _seen -> true end)

  defp unique_item?(_seen_items, ""), do: true

  defp unique_item?(seen_items, item_to_check),
    do:
      Map.has_key?(seen_items, item_to_check) and
        seen_items[item_to_check] === false

  defp file_size_ok?(file_path),
    do: file_path |> File.stat!() |> Map.fetch!(:size) <= max_file_size()

  # The @file_size_coefficient allows for dialing in the right CSV file size
  # given how many concurrent files of some average size may be running on a
  # particular set of resources. Given more time / need, this coefficient should
  # be offloaded to config for env-specific right-sizing. As fo now, this value
  # is set to 0.4 to allow for the "double" case of the :email_or_phone strategy.
  defp max_file_size, do: @file_size_coefficient * :erlang.memory(:total)
end
