defmodule Scraper do
  @moduledoc """
  Documentation for Soup.
  """
@config_file "~/.soup"
  @doc """
  Hello world.

  ## Examples

      iex> Soup.hello()
      :world
  ### to build executable from project
  mix escript.build

  https://www.1001tracklists.com/dj/ericprydz/index.html
  https://www.1001tracklists.com/tracklist/16d0bfj1/sasha-denney-last-night-on-earth-048-lnoe-boat-party-miami-united-states-2019-03-28-2019-05-03.html#tlp_4093761

  """
  def fetch_soup_list do
    case get_saved_location() do
      {:ok, location} ->
        display_soup_list(location) #set location if this returns location map
                                    # acts as a catch all, if @config_file is busted

      _->
      IO.puts("~~~~~Select default location not set, select one now")
      enter_select_location_flow()
    end
  end

  @doc """
    Fetch the name and ID of the location that was saved by `ask_user_to_select_location/1`
  """
  def get_saved_location() do
    case Path.expand(@config_file) |> File.read() do #expand path for config file
    {:ok, location} ->
      try do
        location = :erlang.binary_to_term(location) # read config file locations by unserializing

        case String.strip(location.id) do
          # File contains empty location Id
          "" -> {:empty_location_id}
          _-> {:ok, location}
        end

      rescue
        e in ArgumentError -> e
      end
      {:error, _} -> :error
    end
  end

  def display_soup_list(location) do
    IO.puts("Fetching soups for #{}")

    case Scraper.get_soups(location.id) do #location container location & id
      {:ok, soups} ->
        Enum.each(soups, &(IO.puts " - " <> &1))
        _->
          IO.puts("Unexpected error. Try again")
    end

  end


  @config_file "~/.something"

  @doc """

    enter location and name which will then be saved to config files
  """
  def ask_user_to_select_location(locations) do
    #print list of locations
    locations
    |> Enum.with_index(1)
    |> Enum.each(fn({location, index})-> IO.puts "#{index} - #{location.name}" end) #enum.with_index/2 Returns the enumerable with each element wrapped in a tuple alongside its index.

    case IO.gets("Select a location number:") |> Integer.parse() do # parsing user input
      :error ->
        IO.puts("Invalid selection")
        ask_user_to_select_location(locations)

        {location_x, _} ->
          case Enum.at(locations, location_x-1 ) do
            nil ->
              IO.puts("Invalid location numer yo")
              ask_user_to_select_location(locations)

              location ->
                IO.puts("You've selected the #{location.name} location.")

                File.write!(Path.expand(@config_file), to_string(:erlang.term_to_binary(location)))

                {:ok, location}
          end

    end
  end


  def enter_select_location_flow() do
    IO.puts("Fetching locations ... ")

    case Scraper.get_locations() do
      {:ok, locations} ->
        {:ok, location} = ask_user_to_select_location(locations)
        display_soup_list(location)

      :error ->
        IO.puts("An unexpected error occured, pz try again")
    end
  end

  def get_soups(location_id) do
    url = "https://www.haleandhearty.com/menu/?location=#{location_id}"

    # GET req
    case HTTPoison.get(url) do
      {:ok, response} ->
        case response.status_code do
          200 ->
            soups =
              response.body
              # floki uses the css descendant selector for the find() call
              # Flok.find/2 , only care about p tags in divs
              |> Floki.find("div.category.soups p.menu-item__name")
              # Enum.map/2, return a list of soup names
              |> Enum.map(fn {_, _, [soup]} -> soup end)

            {:ok, soups}

          _ ->
            :error
        end

      _ ->
        :error
    end
  end

  def extract_location_name_and_id({_tag, attrs, children}) do
    {_, _, [name]} =
      Floki.raw_html(children)
      # id/attr selector
      |> Floki.find(".location-card__name")
      # head
      |> hd()

    # tuple to map
    attrs = Enum.into(attrs, %{})
    # return map of location name and id
    %{id: attrs["id"], name: name}
  end

  def get_locations() do
    # Get request
    case HTTPoison.get('https://www.haleandhearty.com/locations/') do
      # pattern match on status code
      {:ok, response} ->
        case response.status_code do
          # pattern match on ok response
          200 ->
            locations =
              response.body
              |> Floki.find(".location-card")
              |> Enum.map(&extract_location_name_and_id/1)
              # sort alpha
              |> Enum.sort(&(&1.name < &2.name))

            # return tuple
            {:ok, locations}

          _ ->
            :error
        end

      _ ->
        :error
    end
  end

  def hello do
    :world
  end
end
