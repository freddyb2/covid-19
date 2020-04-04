#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'io/console'
load 'insee_daily_deaths.rb'

CARRIAGE_UNIX = "\n"
CSV_SEPARATOR = ';'

POPULATION_DATABASE_PATH = '../population/database'
DEATHS_DATABASE_PATH = '../personnes_decedees/database'

YDAYS = (1..365).to_a.freeze

def generate_dep_codes(first_digit, last_digits)
  last_digits.map { |last_digit| "#{first_digit}#{last_digit}" }
end

DEPARTMENTS_CODES = [
    generate_dep_codes('0', (1..9).to_a),
    generate_dep_codes('1', (1..2).to_a + (4..9).to_a),
    generate_dep_codes('2', %w[A B] + (1..9).to_a),
    generate_dep_codes('3', (0..9).to_a),
    generate_dep_codes('4', (0..9).to_a),
    generate_dep_codes('5', (0..9).to_a),
    generate_dep_codes('6', (0..9).to_a),
    generate_dep_codes('7', (0..9).to_a),
    generate_dep_codes('8', (0..9).to_a),
    generate_dep_codes('9', (1..5).to_a),
].flatten.freeze

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

def date_nb_deaths(year, day, nb_deaths_s)
  begin
    {
        year: year,
        yday: Date.new(year, day[0..1].to_i, day[2..3].to_i).yday,
        nb_deaths: nb_deaths_s.to_i,
    }
  rescue
    nil
  end
end

def analyse_series(day, series, years_reference)
  raise "Error not enough elements in series (day #{day} - series.count = #{series.count})" if series.count < (years_reference.count * 1) / 2 || series.count > years_reference.count

  {
      day: day,
      mean_death_rate: mean(series),
      standard_deviation_death_rate: standard_deviation(series)
  }
end

def death_rate(nb_deaths, year, department_code)
  nb_deaths * 100_000 / POPULATIONS[year][department_code].to_f
end

def accumulate_day_death_rate(hash, department_code, daily_nb_deaths)
  hash.merge(
      daily_nb_deaths[:yday] => hash[daily_nb_deaths[:yday]]
                                    .push(death_rate(daily_nb_deaths[:nb_deaths], daily_nb_deaths[:year], department_code))
  )
end

def daily_nb_deaths(department_code, year)
  lines_in_file(DEATHS_DATABASE_PATH, year.to_s, department_code)
      .map { |line| date_nb_deaths(year, *line.split(CSV_SEPARATOR)) }
      .compact
end

def deaths_2020(yday, department_code)
  abs_deaths_total_deaths = DEATHS_2020.total_deaths(department_code, yday)
  {
      nb_deaths_2020: abs_deaths_total_deaths,
      death_rate_2020: death_rate(abs_deaths_total_deaths, 2019, department_code),
  }
end

def over_mortality(daily_data, day_max, day_min)
  selected_data = daily_data.select do |line|
    line[:death_rate_2020] > 0 &&
        line[:day] <= day_max &&
        line[:day] >= day_min
  end
  death_rate_mean, deaths_rate_2020 = selected_data.reduce([0, 0]) { |acc, line| [acc[0] + line[:mean_death_rate], acc[1] + line[:death_rate_2020]] }
  (deaths_rate_2020 / death_rate_mean - 1)
end

OUTPUT_FILE_DATA_FIELDS = %i[day mean standard_deviation]
POPULATIONS = load_populations.freeze
YEARS = (1995..2019).to_a.freeze
OVER_MORTALITY_CRITERIAS = [
    [83, 7],
    [83, 14],
    [83, 21],
].freeze

DEATHS_2020 = Death2020.new

# Years available : 1995..2019
YEARS_REFERENCES = [2015..2019, 2009..2019, 1999..2019]


puts([['reference_years'] + YEARS_REFERENCES.map { |ref| OVER_MORTALITY_CRITERIAS.map { |_| ref } }.flatten].join(CSV_SEPARATOR))
puts([['department'] + YEARS_REFERENCES.map { |_| OVER_MORTALITY_CRITERIAS.map { |day_max, period| "day_#{day_max - period}_to_#{day_max}" } }.flatten].join(CSV_SEPARATOR))
DEPARTMENTS_CODES.each do |department_code|
  puts([
           department_code,
           YEARS_REFERENCES.map do |years_reference|
             data = years_reference
                        .to_a
                        .map { |year| daily_nb_deaths(department_code, year) }
                        .flatten(1)
                        .select { |year_day_deaths| DEATHS_2020.available_ydays.include? year_day_deaths[:yday] }
                        .reduce(Hash.new { [] }) { |hash, year_day_deaths| accumulate_day_death_rate(hash, department_code, year_day_deaths) }
                        .select { |yday, _| yday <= 365 }
                        .map { |day, series| analyse_series(day, series, years_reference) }
                        .map { |datum| datum.merge(deaths_2020(datum[:day], department_code)) }
                        .compact
             OVER_MORTALITY_CRITERIAS.map { |day_max, period| over_mortality(data, day_max, day_max - period) }.flatten
           end
       ].join(CSV_SEPARATOR))
end


