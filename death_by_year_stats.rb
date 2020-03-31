#!/usr/bin/env ruby
# frozen_string_literal: true

CARRIAGE_UNIX = "\n"
POPULATION_DATABASE_PATH = 'population/database'
YDAYS = (1..365).to_a.freeze

def replace_CR_to_unix(string)
  string.gsub!(/\r\n?/, CARRIAGE_UNIX)
end

def files_in_dir(path)
  filenames = `ls #{path}`
  replace_CR_to_unix filenames
  filenames.split(CARRIAGE_UNIX)
end

def lines_in_file(*args)
  lines = File.open(File.join(args)).read
  replace_CR_to_unix lines
  lines.split(CARRIAGE_UNIX)
end

def load_populations
  populations = Hash.new({})
  files_in_dir(POPULATION_DATABASE_PATH).map do |filename|
    # puts "<#{filename.scan(/([^.]*).csv/)}>"
    year = filename[/\d+/]
    populations[year] = lines_in_file(File.join(POPULATION_DATABASE_PATH, filename)).map { |line| line.split(';') }.reduce(populations[year]) { |hash, line_split| hash.merge(line_split[0] => line_split[1]) }
  end
  populations
end


puts load_populations
