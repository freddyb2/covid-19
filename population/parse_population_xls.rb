#!/usr/bin/env ruby
# frozen_string_literal: true

database_dir = 'database'
`rm -rf #{database_dir}`
`mkdir #{database_dir}`

require 'roo'

excel = Roo::Excel.new('estim-pop-dep-sexe-aq-1975-2020.xls')
worksheets = excel.workbook.worksheets
worksheets
    .select { |ws| ws.name.to_i > 0 }
    .each do |worksheet|
  year = worksheet.name
  File.open(File.join(database_dir, "#{year}.csv"), 'w') do |database_file|
    (5..worksheet.last_row_index).to_a
        .map { |row_index| worksheet.row(row_index) }
        .map { |row| [row[0], row[22]] }
        .select { |department, _| department.to_i > 0 }
        .each do |department, population|
      database_file.puts "#{department};#{population}"
    end
  end
end