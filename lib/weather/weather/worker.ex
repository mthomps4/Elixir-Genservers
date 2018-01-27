defmodule Weather.Worker do
  def loop do
    receive do
      {sender_pid, location} -> 
        send(sender_pid, {:ok, temperature_of(location)})
        _ -> IO.puts "I don't know how to process this message!"
    end
    loop()
  end

  def temperature_of(location) do
    result = 
      location 
      |> url_for 
      |> HTTPoison.get
      |> parse_response
    case result do
      {:ok, temp} -> "#{location}: #{temp} deg F"
      :error -> "#{location} Not Found!"
    end
  end

  defp url_for(location) do
    location = URI.encode(location)
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=3e102b406893685d95c8ea1bb867228e"
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> Poison.decode!
    |> compute_temperature
  end
  defp parse_response(_) do
    :error
  end
  defp compute_temperature(json) do
    try do
      temp = ((json["main"]["temp"] * (9/5) )- 459.67) |> Float.round(1)
      {:ok, temp}
    rescue
      _ -> :error
    end
  end
end
