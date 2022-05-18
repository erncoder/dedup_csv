# DedupCsv

Takes the path to an employee-list CSV file together with a desired strategy and
returns a CSV file with _all_ duplicate rows removed, as determined by the
specified strategy.

Note:

- CSV headers must be "First Name", "Last Name", "Email", "Phone", inclusive.
- Valid strategies are `:email`, `:phone`, or `:email_or_phone`.
- Empty strings are _disregarded_ for purposes of determing whether a row is
  duplicated or not.
- The output filename has the format of `[base_original_filename]--deduped--[utc_now_as_unix].csv` and is located in the `output` folder at the base bath.

## Package Installation

This package can be installed in your mix project by adding `dedup_csv` to your
list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dedup_csv, git: "https://github.com/erncoder/dedup_csv.git", tag: "0.1"}
  ]
end
```

## Use as Utility

If you want to run the package as a stand-alone utility, there is a helper
script included with the source files called `dedup.sh`. Running the utility
requires **Elixir 1.13** and access to `mix` from the project base path.

Example use:

```bash
./dedup.sh "path/to/desired.csv" :email
```

Alternatively, the deduplication function can be called directly using `mix`:

```bash
mix run -e "DedupCSV.run(\"path/to/desired.csv\", :email_or_phone)"
```
