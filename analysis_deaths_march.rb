#!/usr/bin/env ruby

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

require 'roo'


class Death2020
  def dematerialized_deaths(dep_code, day)
    deaths_on_day(dep_code, COLUMN_DEMATERIALIZED_DEATHS_2020, day)
  end

  def total_deaths(dep_code, day)
    deaths_on_day(dep_code, COLUMN_TOTAL_DEATHS_2020, day)
  end

  private

  COLUMN_DEMATERIALIZED_DEATHS_2020 = 2
  COLUMN_TOTAL_DEATHS_2020 = 3
  FIRST_DAY_ROW_INDEX = 3

  def cumulated_deaths(column, day, dep_code)
    department_sheet(dep_code).column(column)[day + FIRST_DAY_ROW_INDEX].to_i
  end

  def death_cumulated_before(column, day, dep_code)
    day == 1 ? 0 : cumulated_deaths(column, day - 1, dep_code)
  end

  def deaths_on_day(dep_code, column, day)
    [cumulated_deaths(column, day, dep_code) - death_cumulated_before(column, day, dep_code), 0].max
  end

  def department_sheet(dep_code)
    @workbook.sheet(dep_code)
  end

  def initialize(file)
    @workbook = Roo::Excelx.new(file)
  end
end

def demo
  xlsx = Death2020.new 'deaths_march_2020/2020-03-27_deces_quotidiens_departement.xlsx'
  DEPARTMENTS_CODES.each do |dep_code|
    puts "DEPARTMENT #{dep_code}"
    (1..30)
        .to_a
        .map { |day| [Date.new(2020, 3, day).yday, xlsx.dematerialized_deaths(dep_code, day), xlsx.total_deaths(dep_code, day)] }
        .each { |info| puts info.join(' | ') }
    exit
  end
end

# demo