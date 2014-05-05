scraper-bills
=============

This is a scrapper for bills in the argentinan congress based in: https://github.com/ciudadanointeligente/scrapers/tree/bills_senado_wspublico_deltas


#How it works
It takes the HTML from the Congress in the following URLs:
* http://www1.hcdn.gov.ar/proyectos_search/resultado.asp?giro_giradoA=&odanno=&pageorig=1&fromForm=1&whichpage=1&fecha_fin=[fecha]&fecha_inicio=[fecha]
* http://www1.hcdn.gov.ar/proyectos_search/proyectomovimientos.asp?&id_proy=[id]&tipo=[tram|giro|firm|dict]

It produces an internal Bill representation with the following data (under development)
* uid (número de expediente)
* title (sumario)
* creation_date (fecha de ingreso por mesa de entradas)
* source (cámara de inicio, obtenido a partir del uid)
* initial_chamber (igual al de arriba)
* bill_draft_link (url de la página del proyecto en hcdn o senado)
* subject_areas (comisiones)
* authors (firmantes)

More fields to come.

Then pushes that over to BillIt, where it can be consumed using a BillIt API client (https://github.com/ciudadanointeligente/api-client) or the web interface of the instance (usually http://localhost:3003/bills).

#Requirements
* Linux
* Ruby
* A working installation of BillIt (requires MongoDB) or a remote instance. Check: https://github.com/ciudadanointeligente/bill-it/


#Usage

Modify @api_url in scrappable classes to match the BillIt instance location.

```
cd scraper-bills
bundle install
./bills_runner
```

# About
Congreso Interactivo

www.congresointeractivo.org

Fundación Ciudadano Inteligente

http://www.ciudadanointeligente.org/
