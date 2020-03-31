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
require 'date'

class Death2020
  def dematerialized_deaths(dep_code, yday)
    deaths_on_day(dep_code, COLUMN_DEMATERIALIZED_DEATHS_2020, yday)
  end

  def total_deaths(dep_code, day)
    deaths_on_day(dep_code, COLUMN_TOTAL_DEATHS_2020, day)
  end

  def available_ydays
    @workbooks.keys.map(&:to_a).reduce(:+).flatten.sort
  end

  private

  COLUMN_DEMATERIALIZED_DEATHS_2020 = 2
  COLUMN_TOTAL_DEATHS_2020 = 3
  FIRST_DAY_ROW_INDEX = 4
  FILES = [
      { file: 'deaths_march_2020/2020-03-27_deces_quotidiens_departement.xlsx', days: 61..90 }
  ]

  def cumulated_deaths(column, yday, dep_code)
    department_sheet(dep_code, yday).column(column)[yday - day_range(yday).first + FIRST_DAY_ROW_INDEX].to_i
  end

  def death_cumulated_before(column, yday, dep_code)
    yday == day_range(yday).first ? 0 : cumulated_deaths(column, yday - 1, dep_code)
  end

  def deaths_on_day(dep_code, column, yday)
    [cumulated_deaths(column, yday, dep_code) - death_cumulated_before(column, yday, dep_code), 0].max
  end

  def department_sheet(dep_code, yday)
    @workbooks[day_range(yday)].sheet(dep_code)
  end

  def day_range(yday)
    @workbooks.keys.detect { |days| days.include? yday }
  end

  def initialize
    @workbooks = FILES.map { |entry| [entry[:days], Roo::Excelx.new(entry[:file])] }.to_h
  end
end

def demo
  death2020 = Death2020.new
  DEPARTMENTS_CODES.each do |dep_code|
    puts "DEPARTMENT #{dep_code}"
    death2020.available_ydays
             .map { |yday| [yday, death2020.dematerialized_deaths(dep_code, yday), death2020.total_deaths(dep_code, yday)] }
             .each { |info| puts info.join(' | ') }
    exit
  end
end

# demo