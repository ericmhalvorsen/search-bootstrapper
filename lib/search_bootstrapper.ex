defmodule SearchBootstrapper do
  import SearchBootstrapper.Person

  def start do
    { microseconds, result } = :timer.tc fn ->
      connection = SearchBootstrapper.Person.connect()
      SearchBootstrapper.Person.execute_query(connection)
      SearchBootstrapper.Person.clean_up()
    end
    IO.puts "Bootstrap took #{microseconds / 1_000_000} second(s)."
    { microseconds, result }
  end
end
