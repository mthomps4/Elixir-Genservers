defmodule Weather do
  alias Weather.Worker
  alias Weather.Coordinator

  def temperatures_of(cities) do
    coordinator_pid = 
      spawn(Coordinator, :loop, [[], Enum.count(cities)])

      cities |> Enum.each(fn city -> 
        worker_pid = spawn(Worker, :loop, [])
        send worker_pid, {coordinator_pid, city}
      end)
  end
end

# iex(3)> cities = ["Singapore", "Monaco", "Vatican City", "Hong Kong", "Macau"]
