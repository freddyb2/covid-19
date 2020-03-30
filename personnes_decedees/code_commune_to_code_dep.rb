#!/usr/bin/env ruby
input_file = ARGV[0]

SEPARATOR = ';'

def to_code_dep(code_commune)
  two_first_digits = code_commune[0..1]
  two_first_digits.to_i > 95 ? code_commune[0..2] : two_first_digits
end

puts "treating #{input_file}..."
text = File.open(input_file).read
text.gsub!(/\r\n?/, "\n")
File.open(input_file, 'w') do |output_file|
  text.each_line do |line|
    elements = line.split(SEPARATOR)
    elements[3] = to_code_dep(elements[3])
    next if elements[3].to_i > 976
    output_file.puts elements.join(SEPARATOR)
  end
end

puts "#{input_file} done."
