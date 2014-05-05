# coding: utf-8
require 'billit_representers/models/bill'
require './scrapable_classes'
require 'json'

class BillInfo < StorageableInfo

	def initialize()
		super()
		@model = 'bills'
		@id = ''

		start_date = "01/01/2013" #start_date: get it from a webservice: HTTParty.get('http://billit.ciudadanointeligente.org/bills/last_update').body
    end_date = "01/01/2014" #current date: Time.now.strftime("%d/%m/%Y")

		@update_location = "http://www1.hcdn.gov.ar/proyectos_search/resultado.asp?giro_giradoA=&odanno=&pageorig=1&fromForm=1&whichpage=1&fecha_fin="+end_date+"&fecha_inicio="+start_date

    @data_location = "http://www1.hcdn.gov.ar/proyectos_search/proyectomovimientos.asp?&id_proy="
		@bills_location = 'bills'
		@format = 'application/json'
	end

	def doc_locations  
    # Options posibles

    # tipo_de_proy:
    # proy_expdipN:
    # proy_expdipT:
    # proy_expdipA:
    # proy_iniciado:Diputados
    # dia_inicio:01
    # mes_inicio:03
    # anio_inicio:2009
    # dia_fin:25
    # mes_fin:04
    # anio_fin:2014
    # firmante:
    # selComision:0
    # palabras:
    # selSearchOptions:and
    # txtOdNum:
    # txtODAnio:
    # proy_leynro:
    # chkTramite:on
    # chkDictamenes:on
    # chkFirmantes:on
    # chkComisiones:on
    # ordenar:3
    # pagesize:25
    # button3:LISTAR    

    ### ISSUE: For pagesizes over 64, nokogiri can't parse
    doc = get_html(@update_location, { :query => {:pagesize => 64} }, "POST")

    xml = Nokogiri::HTML(doc)
    projects = xml.xpath('//*[@id="IDSPAN"]/div/div/a[1]/@href').map {|x| x.text }

    projects_ids = xml.xpath('//*[@id="IDSPAN"]/div/div/a[2]/@href').map {|x| x.text.split("id_proy=")[1].split("\"")[0] }
    locations = projects.map {|x| x.split('"')[1]}

    pnum = 0
    infos = xml.xpath('//ul/li/span/div').map {
      |x| 
      info = {}
      info[:"iniciado"] = x.text.split("Iniciado:")[1].strip.split(" ")[0]
      info[:"expediente"] = x.text.split("Iniciado:")[1].strip.split(" ")[2].split("Publicado")[0]
      info[:"publicado_en"] = x.text.split("Publicado en:")[1].split("Fecha:")[0]
      info[:"fecha_ingreso"] = x.text.split("Fecha:")[1].strip[0..9]
      info[:"texto_url"] = locations[pnum]
      info[:"tramite_url"] = @data_location + "&tipo=tram" + projects_ids[pnum]
      info[:"dictamen_url"] = @data_location + "&tipo=dict" + projects_ids[pnum]
      info[:"giro_url"] = @data_location + "&tipo=giro" + projects_ids[pnum]
      info[:"firmantes_url"] = @data_location + "&tipo=firm" + projects_ids[pnum]
      pnum = pnum + 1
      # p "parsing", pnum, info
      info
    }

    puts "got "+pnum.to_s+" items from " + @update_location
    infos

  end

  def get_html url, options = {}, method = "GET"
    cachefile = slug(url);
    if @options[:cache] && File.exist?("cache/"+cachefile)
        puts "Using html cache " + cachefile
        File.read("cache/"+cachefile)
    else
      if method.uppercase == "POST"
        p "Post "+url
        req = HTTParty.post(url, options);
      else
        p "Get "+url
        req = HTTParty.get(url, options);
      end
      save_cache req.body.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'}), cachefile
    end
  end

  def save_cache content, cachefile
    File.open("cache/"+slug(cachefile), 'w+:utf-8') do |file|
      file.write(content.encode("utf-8"))
    end
    content
  end

	def save bill
    req = HTTParty.get([@API_url, @model, bill.uid].join("/"), headers: {"Accept"=>"*/*"});
    # p req 
    # abort
		if req.code != "404"
			puts "Using put."
			put bill
		else
			puts "Using post."
			post bill
		end
	end

	def put bill
    p "put bill"
    bill.put([@API_url, @model, bill.uid].join("/"), @format)
  end

  def post bill
    p "post bill"
    bill.post([@API_url, @model].join("/"), @format)
	end

	def format info
		bill = Billit::Bill.new

    #p info

		# merged_bills = info[:merged_bills].split('/') if info[:merged_bills]

		bill.uid = info[:uid]
		bill.title = info[:title]
		bill.creation_date = info[:creation_date]
		bill.source = info[:source]
		bill.initial_chamber = info[:initial_chamber]
		# bill.current_priority = info[:current_priority]
		# bill.stage = info[:stage]
		# bill.sub_stage = info[:sub_stage]
		# bill.status = info[:status]
		# bill.resulting_document = info[:resulting_document]
		# bill.publish_date = info[:publish_date]
		bill.bill_draft_link = info[:bill_draft_link]
		# bill.merged_bills = merged_bills
		bill.subject_areas = info[:subject_areas]
		bill.authors = info[:authors]
		# #
		# bill.paperworks = info[:paperworks]
		# bill.priorities = info[:priorities]
		# bill.reports = info[:reports]
		# bill.revisions = info[:revisions]
		# bill.documents = info[:documents]
		# bill.directives = info[:directives]
		# bill.remarks = info[:remarks]

    ap bill

		bill
	end

  def slug text
    if text
    text
      .downcase
      .tr(" :/?&","-")
    end
  end

  def get_css html, css
    html.at_css(css).text.strip if html.at_css(css)
  end

  def get_xpath html, xpath
    html.at_xpath(xpath).text.strip if html.at_xpath(xpath)
  end

  def get_info doc

		info = Hash.new
    if doc[:texto_url]
      texto_html = get_html doc[:texto_url]
      html = Nokogiri::HTML(texto_html)
    end

    if doc[:tramite_url]
      tramite_html = get_html doc[:tramite_url]
      tramite = Nokogiri::HTML(tramite_html)
    end

    if doc[:dictamen_url]
      dictamen_html = get_html doc[:dictamen_url]
      dictamen = Nokogiri::HTML(dictamen_html)
    end

    if doc[:giro_url]
      giro_html = get_html doc[:giro_url]
      giro = Nokogiri::HTML(giro_html)
    end

    firmantes_html = get_html doc[:firmantes_url]
    firmantes = Nokogiri::HTML(firmantes_html)

    info[:creation_date] = doc[:fecha_ingreso]
    info[:creation_document] = doc[:publicado_en]
    info[:bill_draft_link] = doc[:texto_url]
    info[:initial_chamber] = doc[:iniciado]
    info[:uid] = doc[:expediente]
    info[:source] = doc[:expediente]



    if info[:initial_chamber] == "D"
      puts "diputadosUID",info[:uid]
      info[:tramite_parlamentario] = get_css html, 'body > table > tr:nth-child(2) > td'
      info[:title] = get_css html, 'body > table > tr:nth-child(3) > td'
      info[:source] = info[:uid].split("-")[1] if info[:uid]
      info[:full_text] = get_css html, 'body'
      info[:authors] = get_css html, 'body > table > tr:nth-child(4) > td'
      info[:authors] = info[:authors].split(" - ") if info[:authors]
      info[:subject_areas] = get_css html, 'body > table > tr:nth-child(5) > td'

  		# # info[:current_priority] = xml.at_css('urgencia_actual').text() if xml.at_css('urgencia_actual')
  		# info[:stage] = xml.at_css('etapa').text() if xml.at_css('etapa')
  		# info[:sub_stage] = xml.at_css('subetapa').text() if xml.at_css('subetapa')
  		# info[:status] = xml.at_css('estado').text() if xml.at_css('estado')
    #   info[:resulting_document] = xml.at_css('leynro').text() if xml.at_css('leynro')
    #   info[:merged_bills] = xml.at_css('refundidos').text() if xml.at_css('refundidos')
    #   info[:publish_date] = xml.at_css('diariooficial').text() if xml.at_css('diariooficial')
  		# hash_fields.keys.each do |field|
  		# 	info[field] = get_hash_field_data xml, field
  		# end
  		# model_fields.keys.each do |field|
  		# 	info[field] = get_model_field_data xml, field
  		# end
    else
      puts "Senado",info[:uid]
      info[:title] =  get_xpath(html, '//tr[7]/td')
      info[:source] =   get_xpath(html, '//body/table[1]/tbody/tr[3]/td')
      info[:full_text] = get_xpath html, '/html/body/div[2]'
      info[:original_text_url] = get_xpath html, '/html/body/div[3]/a/@href'
      info[:authors] = get_xpath html, '//td/a'
      info[:subject_areas] = get_xpath html, '//th/h3'
    end
		info
  end

  def get_hash_field_data nokogiri_xml, field
  	field = field.to_sym
  	field_vals = []
  	path = nokogiri_xml.xpath(hash_fields[field][:xpath])
  	path.each do |field_info|
  		field_val = {}
  		hash_fields[field][:sub_fields].each do |sub_field|
  			name = sub_field[:name]
  			css = sub_field[:css]
  			field_val[name] = field_info.at_css(css).text if field_info.at_css(css)
  		end
  		field_vals.push(field_val)
  	end if path
  	field_vals
  end

  def get_model_field_data nokogiri_xml, field
    "getting model " + field.to_s
  	field_class = ("Billit" + field.to_s.classify).constantize
  	# field_class = field.to_s.classify.constantize
  	field_instances = []
  	path = nokogiri_xml.xpath(model_fields[field][:xpath])
  	path.each do |field_info|
  		field_instance = field_class.new
  		model_fields[field][:sub_fields].each do |sub_field|
  			name = sub_field[:name]
  			css = sub_field[:css]
  			field_instance.send name+'=', field_info.at_css(css).text if field_info.at_css(css)
  			# field_instance[name] = field_info.at_css(css).text if field_info.at_css(css)
  		end
  		field_instances.push(field_instance)
  		# field_class.send field+'=', field_val #ta super malo
  	end if path
  	field_instances
  end

  # Used for documents embedded within a bill,
  # posted/put as hashes instead of having their own model and representer
  def model_fields
  	{
  		paperworks: {
  			xpath: '//tramitacion/tramite',
  			sub_fields: [
  				{
    				name: 'session',
    				css: 'SESION'
    			},
    			{
    				name: 'date',
    				css: 'FECHA'
    			},
    			{
    				name: 'description',
    				css: 'DESCRIPCIONTRAMITE'
    			},
    			{
    				name: 'stage',
    				css: 'ETAPDESCRIPCION'
    			},
    			{
    				name: 'chamber',
    				css: 'CAMARATRAMITE'
    			}
  		 	]
  		},
  		priorities: {
  			xpath: '//urgencias/urgencia',
  			sub_fields: [
    			{
    				name: 'type',
    				css: 'TIPO'
    			},
    			{
    				name: 'entry_date',
    				css: 'FECHAINGRESO'
    			},
    			{
    				name: 'entry_message',
    				css: 'MENSAJEINGRESO'
    			},
    			{
    				name: 'entry_chamber',
    				css: 'CAMARAINGRESO'
    			},
    			{
    				name: 'withdrawal_date',
    				css: 'FECHARETIRO'
    			},
    			{
    				name: 'withdrawal_message',
    				css: 'MENSAJERETIRO'
    			},
    			{
    				name: 'withdrawal_chamber',
    				css: 'CAMARARETIRO'
    			}
    		]
  		},
  		reports: {
  			xpath: '//informes/informe',
  			sub_fields: [
    			{
    				name: 'date',
    				css: 'FECHAINFORME'
    			},
    			{
    				name: 'step',
    				css: 'TRAMITE'
    			},
    			{
    				name: 'stage',
    				css: 'ETAPA'
    			},
    			{
    				name: 'link',
    				css: 'LINK_INFORME'
    			}
    		]
  		},
  		documents: {
  			xpath: '//oficios/oficio',
  			sub_fields: [
    			{
    				name: 'number',
    				css: 'NUMERO'
    			},
    			{
    				name: 'date',
    				css: 'FECHA'
    			},
    			{
    				name: 'step',
    				css: 'TRAMITE'
    			},
    			{
    				name: 'stage',
    				css: 'ETAPA'
    			},
    			{
    				name: 'type',
    				css: 'TIPO'
    			},
    			{
    				name: 'chamber',
    				css: 'CAMARA'
    			},
    			{
    				name: 'link',
    				css: 'LINK_OFICIO'
    			}
    		]
  		},
  		directives: {
  			xpath: '//indicaciones/indicacion',
  			sub_fields: [
    			{
    				name: 'date',
    				css: 'FECHA'
    			},
    			{
    				name: 'step',
    				css: 'TRAMITE'
    			},
    			{
    				name: 'stage',
    				css: 'ETAPA'
    			},
    			{
    				name: 'link',
    				css: 'LINK_INDICACION'
    			}
    		]
  		},
  		remarks: {
  			xpath: '//observaciones/observacion',
  			sub_fields: [
    			{
    				name: 'date',
    				css: 'FECHA'
    			},
    			{
    				name: 'step',
    				css: 'TRAMITE'
    			},
    			{
    				name: 'stage',
    				css: 'ETAPA'
    			}
    		]
  		},
  		revisions: {
  			xpath: '//comparados/comparado',
  			sub_fields: [
  				{
    				name: 'description',
    				css: 'COMPARADO'
    			},
    			{
    				name: 'link',
    				css: 'LINK_COMPARADO'
    			}
    		]
  		}
  	}
  end

  # Used for documents embedded within a bill,
  # stored as hashes instead of having their own model and representer
  def hash_fields
  	{
  		authors: {
  			xpath: '//autores/autor',
  			sub_fields: [
  				{
    				name: 'author',
    				css: 'PARLAMENTARIO'
    			}
    		]
  		},
  		subject_areas: {
  			xpath: '//materias/materia',
  			sub_fields: [
    			{
    				name: 'subject_area',
    				css: 'DESCRIPCION'
    			}
    		]
  		}
  	}
  end
end
