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
xlsx = Roo::Excelx.new('deaths_march_2020/2020-03-27_deces_quotidiens_departement.xlsx')
COLUMN_DEMATERIALIZED_DEATHS_2020 = 2
COLUMN_TOTAL_DEATHS_2020 = 3
FIRST_DAY_ROW_INDEX = 3
DEPARTMENTS_CODES.each do |dep_code|
  department_sheet = xlsx.sheet(dep_code)
  (1..30)
      .to_a
      .map { |day| ([Date.new(2020, 3, day).yday] + [COLUMN_DEMATERIALIZED_DEATHS_2020, COLUMN_TOTAL_DEATHS_2020].map { |column| department_sheet.column(column)[day + FIRST_DAY_ROW_INDEX].to_i }) }
      .each { |info| puts info.join(' | ') }
  # puts "#{dep_code}=> #{department_sheet.row_count}"
  exit
end