# coding: utf-8
require 'rubygems'
require 'nokogiri'
# require 'rest-client'
require 'httparty'
require 'pdf-reader'
require 'open-uri'
require 'awesome_print'

module RestfulApiMethods

	@model =  ''
	@API_url = ''

	def format info
		info
	end

	def put formatted_info
		HTTParty.put [@API_url, @model, @id].join("/"), formatted_info
	end
end

class StorageableInfo
	include RestfulApiMethods

	def initialize(location = '')
		# @API_url = 'http://billit.ciudadanointeligente.org'
		@API_url = 'http://billit.congresointeractivo.org'
		@location = location
	end

	def process  opts={}
		@options = opts
		
		f = File.open('scraping_errors.txt', 'a')
		doc_locations.each do |doc_location|
#			 begin
				#puts doc_location
				doc = read doc_location
				puts '#read'
				info = get_info doc
				puts '#got'
				formatted_info = format info
				puts '#formatted'
				save formatted_info
				puts '#saved'
##		 	rescue Exception=>e
#			 f.puts "EXCEPTION"
#		         	f.puts doc_location
#			         f.puts e
#			         puts e
#		 	end
		end
   		if (@total_pages.to_i > @page)
			process(opts)
		end
	end

	def read location = @location
		# it would be better if instead we used
		# mimetype = `file -Ib #{path}`.gsub(/\n/,"")
		if location.class.name != 'String'
			doc = location
		elsif !location.scan(/pdf/).empty?
			doc_pdf = PDF::Reader.new(open(location))
			doc = ''
			doc_pdf.pages.each do |page|
				doc += page.text
			end
		else
			doc = open(location).read
		end
		doc
	end

#----- Undefined Functions -----

	def doc_locations
		[@location]
	end

	def get_info doc
		doc
	end
end

