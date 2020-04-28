require 'roo'
require 'date'

CARRIAGE_UNIX = "\n"

module InseeDailyDeaths
  def total_deaths(dep_code, day)
    raise 'not implemented'
  end

  def available_ydays
    raise 'not implemented'
  end
end

def replace_cr_to_unix(string)
  string.gsub!(/\r\n?/, CARRIAGE_UNIX)
end

def remove_carriage(string)
  string.gsub!(CARRIAGE_UNIX, '')
end

def extract_data(split)
  return if split[0].to_i < 2020 || split[9].to_i > 95
  {
    yday: Date.new(split[0].to_i, split[1].to_i, split[2].to_i).yday,
    dep_code: split[9]
  }
end

def reduce_by_yday_dep(data, hash)
  yday = data[:yday]
  dep_code = data[:dep_code]
  hash.merge(yday => hash[yday].merge(dep_code => hash[yday][dep_code] + 1))
end

def load_data
  filename = 'DC_jan2018-avr2020_det.csv'
  lines = File.open(filename).read
  replace_cr_to_unix(lines)
  lines.split(CARRIAGE_UNIX)
    .map { |line| extract_data line.split(';') }
    .compact
    .reduce(Hash.new { (Hash.new 0) }) { |hash, data| reduce_by_yday_dep(data, hash) }
end

class Death2020
  include InseeDailyDeaths

  def total_deaths(dep_code, yday)
    @data[yday][dep_code]
  end

  def available_ydays
    @data.keys
  end

  private

  def initialize
    @data = load_data
  end
end