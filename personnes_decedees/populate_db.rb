#!/usr/bin/env ruby

csv_dir = 'deces_csv'
database_dir = 'database'

`rm -rf #{database_dir}`
`mkdir #{database_dir}`

def replace_CR_to_unix(string)
  string.gsub!(/\r\n?/, CARRIAGE_UNIX)
end

def remove_carriage(string)
  string.gsub!(CARRIAGE_UNIX, '')
end

database = Hash.new(Hash.new(0))

files = `ls #{csv_dir}`
CARRIAGE_UNIX = "\n"
files.gsub!(/\r\n?/, CARRIAGE_UNIX)
files.each_line do |file|
  filename = file
  replace_CR_to_unix filename
  remove_carriage filename
  puts "#{filename}..."
  filepath = File.join(csv_dir, filename)
  lines = File.open(filepath).read
  replace_CR_to_unix(lines)
  database = lines.split(CARRIAGE_UNIX)
                 .map { |line| line.split(';') }
                 .reject { |elements| elements[3].to_i == 0 }
                 .map { |elements| [elements[2][0..3] + "_" + elements[3], elements[2][4..7]] }
                 .reduce(database) { |hash, couple| hash.merge(couple[0] => hash[couple[0]].merge(couple[1] => hash[couple[0]][couple[1]] + 1)) }
  puts '  -> done'
end

database.keys.sort.each do |year_dep|
  year_and_dep = year_dep.split('_')
  year = year_and_dep[0]
  department = year_and_dep[1]
  puts "#{year}/#{department}"
  year_dir_path = File.join(database_dir, year)
  Dir.mkdir(year_dir_path) unless File.directory?(year_dir_path)
  nb_deces_by_day = database[year_dep]
  database_filename = File.join(year_dir_path, department)
  File.open(database_filename, 'a') do |database_file|
    nb_deces_by_day.keys.sort.each do |day|
      database_file.puts "#{day};#{nb_deces_by_day[day]}"
    end
  end
end
