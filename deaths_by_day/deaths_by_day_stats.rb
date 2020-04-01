#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'io/console'
load 'analysis_deaths_march.rb'

CARRIAGE_UNIX = "\n"
CSV_SEPARATOR = ';'

POPULATION_DATABASE_PATH = '../population/database'
DEATHS_DATABASE_PATH = '../personnes_decedees/database'

STATS_DIR = 'stats'
`rm -rf #{STATS_DIR}`
`mkdir #{STATS_DIR}`

DEATHS_2020 = Death2020.new
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

OUTPUT_FILE_DATA_FIELDS = %i[day mean standard_deviation dematerialized_deaths_2020 total_deaths_2020]
OVER_MORTALITY_CRITERIAS = [
    [:total_deaths_2020, 76, 76 - 7],
    [:total_deaths_2020, 76, DEATHS_2020.available_ydays.first],
    [:dematerialized_deaths_2020, 76, DEATHS_2020.available_ydays.first],
    [:dematerialized_deaths_2020, 80, DEATHS_2020.available_ydays.first],
].freeze

def replace_cr_to_unix(string)
  string.gsub!(/\r\n?/, CARRIAGE_UNIX)
end

def files_in_dir(path)
  filenames = `ls #{path}`
  replace_cr_to_unix filenames
  filenames.split(CARRIAGE_UNIX)
end

def lines_in_file(*args)
  filepath = File.join(args)
  return [] unless File.exist?(filepath)

  lines = File.open(filepath).read
  replace_cr_to_unix lines
  lines.split(CARRIAGE_UNIX)
end

def accumulate_department_population(hash, department_code, nb_deaths)
  hash.merge(department_code => nb_deaths.to_i)
end

def population_by_department(department_populations)
  department_populations
      .map { |line| line.split(CSV_SEPARATOR) }
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

def analyse_series(day, series)
  return nil if day > 365
  raise "Error not enough elements in series (day #{day} - series.count = #{series.count})" if series.count < (YEARS.count * 2) / 3 || series.count > YEARS.count

  {
      day: day,
      mean: mean(series),
      standard_deviation: standard_deviation(series)
  }
end

def accumulate_day_death_rate(hash, department_code, year, day, nb_deaths)
  hash.merge(day => hash[day].push(nb_deaths * 100000 / POPULATIONS[year][department_code].to_f))
end

def day_deaths_couples(department_code, year)
  lines_in_file(DEATHS_DATABASE_PATH, year.to_s, department_code)
      .map { |line| year_yday_deaths(year, *line.split(CSV_SEPARATOR)) }
      .compact
end

def deaths_for_100000_in_2019(deaths, department_code)
  (deaths * 100_000) / POPULATIONS[2019][department_code].to_f
end

def deaths_2020(yday, department_code)
  {
      dematerialized_deaths_2020: DEATHS_2020.dematerialized_deaths(department_code, yday),
      total_deaths_2020: DEATHS_2020.total_deaths(department_code, yday)
  }.map { |key, deaths| [key, deaths_for_100000_in_2019(deaths, department_code)] }.to_h
end

def over_mortality(daily_data, criteria, day_max, day_min)
  selected_data = daily_data.select { |line| line[criteria] > 0 && line[:day] <= day_max && line[:day] >= day_min }
  mean, deaths2020 = selected_data.reduce([0, 0]) { |acc, line| [acc[0] + line[:mean], acc[1] + line[criteria]] }
  (deaths2020 / mean - 1)
end

POPULATIONS = load_populations.freeze
puts((["department"] + OVER_MORTALITY_CRITERIAS.map { |criteria, day_max, day_min| "#{criteria}_day_#{day_min}_to_#{day_max}" }).join(CSV_SEPARATOR))
DEPARTMENTS_CODES.map do |department_code|
  File.open(File.join(STATS_DIR, "#{department_code}.csv"), 'w') do |output_file|
    output_file.puts OUTPUT_FILE_DATA_FIELDS.join(CSV_SEPARATOR)
    data = YEARS
               .map { |year| day_deaths_couples(department_code, year) }
               .flatten(1)
               .reduce(Hash.new { [] }) { |hash, year_day_deaths| accumulate_day_death_rate(hash, department_code, *year_day_deaths) }
               .map(&method(:analyse_series))
               .compact
               .sort { |a, b| a[:day] <=> b[:day] }
               .select { |datum| DEATHS_2020.available_ydays.include? datum[:day] }
               .map { |datum| datum.merge(deaths_2020(datum[:day], department_code)) }

    puts(([department_code] + OVER_MORTALITY_CRITERIAS.map { |criteria, day_max, day_min| over_mortality(data, criteria, day_max, day_min) }).join(CSV_SEPARATOR))

    data
        .map { |datum| OUTPUT_FILE_DATA_FIELDS.map { |key| datum[key] } }
        .each { |datum| output_file.puts datum.join(CSV_SEPARATOR) }
  end
end
