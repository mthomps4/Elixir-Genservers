defmodule Genweather.Worker do
  use GenServer
  # Local Naming 
  #@name WW
  # I can replace pid with @name below 
  # I no longer have to catch pid but could for safty.

  ## Client API 
  def start_link(opts \\ []) do
    # Local Naming --
    # GenServer.start_link(__MODULE__, :ok, opts ++ [name: MW])
    GenServer.start_link(__MODULE__, :ok, opts)
  end
  def get_stats(pid) do
    GenServer.call(pid, :get_stats)
  end
  def reset_stats(pid) do
    GenServer.cast(pid, :reset_stats)
  end
  def stop(pid) do
    GenServer.cast(pid, :stop)
  end
  def get_temperature(pid, location) do
    GenServer.call(pid, {:location, location})
  end
  ## Server Callbacks 
  def init(:ok) do
    {:ok, %{}}
  end
    # Genserver.call expects handle_call 
    # _from has {pid, tag} -- pid from client 
  def handle_call({:location, location}, _from, stats) do
    case temperature_of(location) do
      {:ok, temp} -> 
        new_stats = update_stats(stats, location)
        {:reply, "#{temp}C", new_stats}
      _any -> {:reply, :error, stats}
    end
  end
  def handle_call(:get_stats, _from, stats) do
    # Not modifying stats just passing along.
    {:reply, stats, stats}
  end
  def handle_cast(:reset_stats, _stats) do
    {:noreply, %{}}
  end
  def handle_cast(:stop, stats) do
    {:stop, :normal, stats}
  end
  # Handle Info is used for any call to pid that's not handled by cast or call
  def handle_info(msg, stats) do
    IO.puts "received #{inspect msg}"
    {:noreply, stats}
  end
  def terminate(reason, stats) do
    # We could write to a file, DB, etc
    IO.puts "server terminated because of #{inspect reason}"
      inspect stats
    :ok
  end
  ## Helper Functions 
  defp temperature_of(location) do
    location |> url_for |> HTTPoison.get |> parse_response
  end
  defp url_for(location) do
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=3e102b406893685d95c8ea1bb867228e"
  end
  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body 
    |> Poison.decode! 
    |> compute_temperature
  end
  defp parse_response(_any) do
    :error
  end
  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
      {:ok, temp}
    rescue
      _any -> :error
    end
  end
  defp update_stats(old_stats, location) do
    case Map.has_key?(old_stats, location) do
      true -> 
        Map.update!(old_stats, location, &(&1 + 1))
        # Map.update!(old_stats, location, fn(val) -> val +1 end)
      false -> 
        Map.put_new(old_stats, location, 1)
    end
  end
end