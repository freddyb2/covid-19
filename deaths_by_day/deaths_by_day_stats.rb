#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'

require 'io/console'

def continue_story
  print "press any key"
  STDIN.getch
  print "            \r" # extra space to overwrite in case next sentence is short
end

CARRIAGE_UNIX = "\n"
POPULATION_DATABASE_PATH = '../population/database'
DEATHS_DATABASE_PATH = '../personnes_decedees/database'
YDAYS = (1..365).to_a.freeze
YEARS = (1975..2019).to_a.freeze

def generate_dep_codes(first_digit, last_digits)
  last_digits.map { |last_digit| "#{first_digit}#{last_digit}" }
end

DEPARTMENTS_CODES = [
    generate_dep_codes('0', (1..9).to_a),
    generate_dep_codes('1', (0..9).to_a),
    generate_dep_codes('2', (1..9).to_a), # Corse ignored for the moment
    generate_dep_codes('3', (0..9).to_a),
    generate_dep_codes('4', (0..9).to_a),
    generate_dep_codes('5', (0..9).to_a),
    generate_dep_codes('6', (0..9).to_a),
    generate_dep_codes('7', (0..9).to_a),
    generate_dep_codes('8', (0..9).to_a),
    generate_dep_codes('9', (1..5).to_a),
].flatten.freeze

def replace_CR_to_unix(string)
  string.gsub!(/\r\n?/, CARRIAGE_UNIX)
end

def files_in_dir(path)
  filenames = `ls #{path}`
  replace_CR_to_unix filenames
  filenames.split(CARRIAGE_UNIX)
end

def lines_in_file(*args)
  filepath = File.join(args)
  return [] unless File.exist?(filepath)

  lines = File.open(filepath).read
  replace_CR_to_unix lines
  lines.split(CARRIAGE_UNIX)
end

#TODO refactor in a more functional way
def load_populations
  populations = Hash.new({})
  files_in_dir(POPULATION_DATABASE_PATH).map do |filename|
    year = filename[/\d+/]
    populations[year.to_i] = lines_in_file(POPULATION_DATABASE_PATH, filename).map { |line| line.split(';') }.reduce(populations[year]) { |hash, line_split| hash.merge(line_split[0] => line_split[1].to_i) }
  end
  populations
end


def mean serie
  return 0 if serie.empty?

  serie.reduce(:+) / serie.count
end

def standard_deviation(serie)
  return 0 if serie.count < 2

  mean = mean(serie)
  Math.sqrt(serie.inject(0) { |accum, i| accum + ((i - mean) ** 2) } / (serie.length - 1).to_f)
end

def to_date_nd_deaths(year, split)
  begin
    day = split[0]
    date = Date.new(year, day[0..1].to_i, day[2..3].to_i)
    nb_deaths = split[1].to_i
    [year, date.yday, nb_deaths]
  rescue
    nil
  end
end


POPULATIONS = load_populations.freeze

def format_serie(day, series)
  return nil if day > 365
  raise "Error not enough elements in series (day #{day} - series.count = #{series.count})" if series.count < 32

  [day, mean(series), standard_deviation(series)]
end

STATS_DIR = 'stats'
`rm -rf #{STATS_DIR}`
`mkdir #{STATS_DIR}`

DEPARTMENTS_CODES.map do |department_code|
  File.open(File.join(STATS_DIR, "#{department_code}.csv"), 'w') do |output_file|
    YEARS.map do |year|
      lines_in_file(DEATHS_DATABASE_PATH, year.to_s, department_code)
          .map { |line| line.split(';') }
          .map { |split| to_date_nd_deaths(year, split) }
          .compact
    end.flatten(1)
        .reduce(Hash.new { [] }) do |hash, year_day_deaths|
      year = year_day_deaths[0]
      day = year_day_deaths[1]
      nb_deaths = year_day_deaths[2]
      death_by_pop = nb_deaths * 100000 / POPULATIONS[year][department_code].to_f
      hash.merge(day => hash[day].push(death_by_pop))
    end.map(&method(:format_serie)).compact.each { |data| output_file.puts data.join(';') }
  end
end

# puts deaths_by_day

