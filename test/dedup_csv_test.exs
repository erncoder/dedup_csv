defmodule DedupCSVTest do
  use ExUnit.Case
  alias DedupCSV, as: TestMe

  @moduletag :capture_log
  @strategies [:email, :phone, :email_or_phone]

  doctest TestMe

  describe "run/2" do
    test "non-existent file returns error tuple" do
      Enum.each(@strategies, fn strat ->
        assert {:error, "file doesn't exist"} = TestMe.run("outerspace/file.file", strat)
      end)
    end

    test "empty csv returns error tuple" do
      Enum.each(@strategies, fn strat ->
        assert {:error, "empty, invalid, or fully-duplicated CSV"} =
                 TestMe.run("test/mock_data/empty_no_headers.csv", strat)
      end)
    end

    test "empty csv (headers only) returns error tuple" do
      Enum.each(@strategies, fn strat ->
        assert {:error, "empty, invalid, or fully-duplicated CSV"} =
                 TestMe.run("test/mock_data/empty.csv", strat)
      end)
    end

    test "broken csv returns error tuple" do
      Enum.each(@strategies, fn strat ->
        assert {:error, "empty, invalid, or fully-duplicated CSV"} =
                 TestMe.run("test/mock_data/broken.csv", strat)
      end)
    end

    test "fully duplicated csv creates a csv with only the rows with empty email and phone" do
      Enum.each(@strategies, fn strat ->
        assert {:ok, filename} = TestMe.run("test/mock_data/full_duplicate.csv", strat)

        assert %{"Email" => "", "Phone" => ""} =
                 filename |> File.stream!() |> CSV.decode!(headers: true) |> Enum.random()
      end)
    end

    test "valid csv reduces idempotently" do
      Enum.each(@strategies, fn strat ->
        assert {:ok, filename} = TestMe.run("test/mock_data/valid.csv", strat)
        assert {:ok, filename2} = TestMe.run("test/mock_data/valid.csv", strat)
        assert get_file_size(filename) == get_file_size(filename2)
        assert {:ok, filename3} = TestMe.run(filename2, strat)
        assert {:ok, filename4} = TestMe.run(filename3, strat)
        assert get_file_size(filename3) == get_file_size(filename4)
      end)
    end

    test "valid csv has no duplicates" do
      Enum.each(@strategies, fn strat ->
        assert {:ok, filename} = TestMe.run("test/mock_data/valid.csv", strat)

        generated_rows =
          filename |> File.stream!() |> CSV.decode!(headers: true) |> Enum.to_list()

        same_length? =
          case(strat) do
            :email ->
              uniq =
                Enum.uniq_by(generated_rows, fn
                  %{"Email" => ""} -> make_ref()
                  %{"Email" => email} -> email
                end)

              length(uniq) == length(generated_rows)

            :phone ->
              uniq =
                Enum.uniq_by(generated_rows, fn
                  %{"Phone" => ""} -> make_ref()
                  %{"Phone" => phone} -> phone
                end)

              length(uniq) == length(generated_rows)

            :email_or_phone ->
              email_uniq =
                Enum.uniq_by(generated_rows, fn
                  %{"Email" => ""} -> make_ref()
                  %{"Email" => email} -> email
                end)

              phone_uniq =
                Enum.uniq_by(generated_rows, fn
                  %{"Phone" => ""} -> make_ref()
                  %{"Phone" => phone} -> phone
                end)

              length(email_uniq) == length(generated_rows)
              length(phone_uniq) == length(generated_rows)
          end

        assert same_length?
      end)
    end
  end

  defp get_file_size(filename), do: filename |> File.stat!() |> Map.fetch!(:size)
end
