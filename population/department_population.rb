CARRIAGE_UNIX = "\n"
CSV_SEPARATOR = ';'


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

POPULATION_DATABASE_PATH = 'database'

result = population_by_department lines_in_file(POPULATION_DATABASE_PATH, '2020.csv')
puts result.select { |_, population| population < 500000 }.map { |dep, _| dep }.inspect