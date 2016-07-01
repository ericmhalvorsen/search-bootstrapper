defmodule SearchBootstrapper.Person do
  import Enum
  import Map
  import String

  def connect do
    connection_string = 'Driver={FreeTDS};Server=172.16.110.200;Database=ARCAS_WAREHOUSE_QA;Uid=ARCADIAHOSTED\\ehalvorsen;Pwd=Viscousness0312*****;Port=1433'
    :odbc.start()
    { :ok, connection } = :odbc.connect(connection_string, [])
    connection
  end

  def execute_query(connection) do
    columns = %{
      "address" => "patinfo-Address_1",
      "city"    => "patinfo-City",
      "dob"     => "patinfo-DOB__dt",
      "id"      => "PersonID",
      "name"    => "Name",
      "sex"     => "patinfo-Sex",
      "state"   => "patinfo-State",
      "zip"     => "patinfo-Zip",
    }
    column_formatter = fn (key) -> "\"" <> columns[key] <> "\" as " <> key end
    columns = rstrip(rstrip(join(map(keys(columns), column_formatter), ", ")), ?,)
    query = "SELECT TOP 300000" <> columns <> " FROM rpt.CommonReportFields WHERE PersonActiveInd = 1;"
    { :ok, file } = File.open "patient-search", [:write]
    case :odbc.sql_query(connection, String.to_char_list(query)) do
      { :selected, cols, results } -> write_redis_inserts(results, file)
    end
    File.close(file)
    IO.puts :os.cmd('redis-cli --pipe < patient-search')
  end

  def write_redis_inserts(db_records, file) do
    IO.binwrite file, Enum.reduce(db_records, "", fn(db_record, total) ->
      {_, _, dob, id, name, _, _, _} = db_record
      { :ok, item } = Poison.encode(%{id: id, name: name, data: Tuple.to_list(db_record)})
      result = prefixes_for_phrase([name, dob])
      |> Enum.reduce("", fn(prefix, total) ->
        total <> redis_protocol(["SADD", "patient-search-index:#{prefix}", id])
      end)
      total <> redis_protocol(["HSET", "patient-search-data", id, item]) <> result
    end)
  end

  def redis_protocol(arglist) do
    string = arglist
    |> Enum.map(fn(arg) -> "$#{byte_size(to_string(arg))}\r\n#{arg}\r\n" end)
    |> Enum.join
    "*#{Enum.count(arglist)}\r\n" <> string
  end

  def prefixes_for_phrase(phrase) do
    valid_words(Enum.join(phrase, " "))
    |> Enum.map(fn(word) ->
      Enum.map((1..(String.length(word))), fn(length) ->
        String.slice(word, 0, length)
      end)
    end)
    |> List.flatten
    |> Enum.uniq
  end

  def valid_words(term) do
    normalize(term)
    |> String.split(" ")
    |> Enum.sort
    |> Enum.reject(fn(word) -> String.length(word) < 1 end)
  end

  def normalize(string) do
    to_string(string)
    |> String.downcase
    |> String.replace(~r/[^\w+\ ]/i, "")
    |> String.strip
  end

  def clean_up do
    :odbc.stop()
  end
end

