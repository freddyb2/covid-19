#!/usr/bin/env ruby
# frozen_string_literal: true

CARRIAGE_UNIX = "\n"
POPULATION_DATABASE_PATH = 'population/database'

def replace_CR_to_unix(string)
  string.gsub!(/\r\n?/, CARRIAGE_UNIX)
end

def load_populations
  filenames = `ls #{POPULATION_DATABASE_PATH}`
  replace_CR_to_unix filenames
  populations = Hash.new({})
  filenames.split(CARRIAGE_UNIX).map do |filename|
    # puts "<#{filename.scan(/([^.]*).csv/)}>"
    year = filename[/\d+/]
    lines = File.open(File.join(POPULATION_DATABASE_PATH, filename)).read
    replace_CR_to_unix lines
    populations[year] = lines.split(CARRIAGE_UNIX).map { |line| line.split(';') }.reduce(populations[year]) { |hash, line_split| hash.merge(line_split[0] => line_split[1]) }
  end
  populations
end



puts load_populations
