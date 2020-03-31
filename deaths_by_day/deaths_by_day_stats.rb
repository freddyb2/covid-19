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
YEARS = (1995..2019).to_a.freeze

def generate_dep_codes(first_digit, last_digits)
  last_digits.map { |last_digit| "#{first_digit}#{last_digit}" }
end

DEPARTMENTS_CODES = [
    generate_dep_codes('0', (1..9).to_a),
    generate_dep_codes('1', (0..9).to_a),
    generate_dep_codes('2', %w[A B] + (1..9).to_a),
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

def accumulate_department_population(hash, department_code, nb_deaths)
  hash.merge(department_code => nb_deaths)
end

def population_by_department(department_populations)
  department_populations
      .map { |line| line.split(';') }
      .reduce({}) { |hash, department_population| accumulate_department_population(hash, *department_population) }
end

def accumulate_year_dep_population(hash, year, dep_deaths)
  hash.merge(year => population_by_department(dep_deaths))
end

def load_populations
  files_in_dir(POPULATION_DATABASE_PATH)
      .map { |filename| [filename[/\d+/].to_i, lines_in_file(POPULATION_DATABASE_PATH, filename)] }
      .reduce({}) { |hash, year_dep_population| accumulate_year_dep_population(hash, *year_dep_population) }
end

def mean(series)
  return 0 if series.empty?

  series.reduce(:+) / series.count
end

def standard_deviation(series)
  return 0 if series.count < 2

  mean = mean(series)
  Math.sqrt(series.inject(0) { |accum, i| accum + ((i - mean) ** 2) } / (series.length - 1).to_f)
end

def year_yday_deaths(year, day, nb_deaths_s)
  begin
    date = Date.new(year, day[0..1].to_i, day[2..3].to_i)
    [year, date.yday, nb_deaths_s.to_i]
  rescue
    nil
  end
end

POPULATIONS = load_populations.freeze

def format_serie(day, series)
  return nil if day > 365
  raise "Error not enough elements in series (day #{day} - series.count = #{series.count})" if series.count < (YEARS.count * 2) / 3 || series.count > YEARS.count

  [day, mean(series), standard_deviation(series)]
end

STATS_DIR = 'stats'
`rm -rf #{STATS_DIR}`
`mkdir #{STATS_DIR}`

def accumulate_day_death_rate(hash, department_code, year, day, nb_deaths)
  hash.merge(day => hash[day].push(nb_deaths * 100000 / POPULATIONS[year][department_code].to_f))
end

def day_deaths_couples(department_code, year)
  lines_in_file(DEATHS_DATABASE_PATH, year.to_s, department_code)
      .map { |line| year_yday_deaths(year, *line.split(';')) }
      .compact
end

DEPARTMENTS_CODES.map do |department_code|
  File.open(File.join(STATS_DIR, "#{department_code}.csv"), 'w') do |output_file|
    output_file.puts "POPULATION_2019;#{POPULATIONS[2019][department_code]}"
    output_file.puts "day;mean;standard_deviation"
    YEARS
        .map { |year| day_deaths_couples(department_code, year) }
        .flatten(1)
        .reduce(Hash.new { [] }) { |hash, year_day_deaths| accumulate_day_death_rate(hash, department_code, *year_day_deaths) }
        .map(&method(:format_serie))
        .compact
        .sort { |a, b| a[0] <=> b[0] }
        .each { |data| output_file.puts data.join(';') }
  end
end


