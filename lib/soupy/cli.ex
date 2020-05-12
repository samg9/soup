defmodule Soupy.CLI do

	def main(argv) do
		argv
		|> parse_args()
		|> process()
	end

	def parse_args(argv) do #parse_args/1 converts command line args to tuples
		args = OptionParser.parse(
			argv,
			strict: [help: :boolean, locations: :boolean],
			alias: [h: :help]
		)

		case args do # pattern match on tuples
			{[help: true], _, _} ->
				:help

			{[],[],[{"-h", nil}]} ->
		    	:help

			{[locations: true],_ ,_} ->
		    	:list_locations

			{[],[],[]} ->
		    	:list_soups

		   _->
		    :invalid_arg
		end
	end

	def process(:help) do
		IO.puts """
		soup --locations # select default location for listing soups
		soup #list the soups for a default location
		"""
		System.halt(0)
	end

	def process(:list_locations) do
		Scraper.enter_select_location_flow()
	end

	def process(:list_soups) do
		Scraper.fetch_soup_list()
	end


	def process(:invalid_arg) do
		IO.puts "Invalid argument(s) passed. See usage below or w.e."
		process(:help)
	end


end
