require 'roo'
require 'date'

module InseeDailyDeaths
  def total_deaths(dep_code, day)
    raise 'not implemented'
  end

  def available_ydays
    raise 'not implemented'
  end
end

class InseeExcelFile
  include InseeDailyDeaths

  def total_deaths(dep_code, day)
    deaths_on_day(dep_code, COLUMN_TOTAL_DEATHS_2020, day)
  end

  def available_ydays
    @day_range.to_a
  end

  private

  COLUMN_TOTAL_DEATHS_2020 = 3
  FIRST_DAY_ROW_INDEX = 4

  def cumulated_deaths(column, yday, dep_code)
    @workbook.sheet(dep_code).column(column)[yday - @day_range.first + FIRST_DAY_ROW_INDEX].to_i
  end

  def death_cumulated_before(column, yday, dep_code)
    yday == @day_range.first ? 0 : cumulated_deaths(column, yday - 1, dep_code)
  end

  def deaths_on_day(dep_code, column, yday)
    [cumulated_deaths(column, yday, dep_code) - death_cumulated_before(column, yday, dep_code), 0].max
  end

  def initialize(file, day_range)
    @workbook = Roo::Excelx.new(file)
    @day_range = day_range
  end
end

class Death2020
  include InseeDailyDeaths

  def total_deaths(dep_code, yday)
    daily_death(yday)&.total_deaths(dep_code, yday) || 0
  end

  def available_ydays
    @available_ydays ||= FILES.map(&:available_ydays).reduce(:+).flatten.sort
  end

  private

  FILES = [
      InseeExcelFile.new('data_insee_2020/2020-04-10_deces_quotidiens_departement.xlsx', 61..90)
  ].freeze

  def daily_death(yday)
    FILES.detect { |file| file.available_ydays.include? yday }
  end
end