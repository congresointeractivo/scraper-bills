#!/usr/bin/env ruby
# encoding: utf-8

require './bill_info'
require 'optparse'

options = {}
options[:cache] = true

optparse = OptionParser.new do |option_parser|
  option_parser.banner = "Usage: parser_diputados [options]"

  option_parser.on("-c", "--[no-]cache", "Use cache if exist") do |c|
    options[:cache] = c
  end

end

optparse.parse!

if !(defined? Test::Unit::TestCase)
	BillInfo.new.process options
end
