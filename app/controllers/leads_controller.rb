class LeadsController < ApplicationController
  CLOSE_API_KEY = 'api_6D5d2FMmcNMQqrRmw0o5QB.3oWH6P1b4eX5TW3LpWngOU'
  SMART_VIEW_ID = 'save_Mrwcxby2q272p2fapBKRC1B2ucetYVuJCRD3Cj3aimn'



  def index
    @leads = fetch_leads_by_smartview
  end

  private

  def fetch_leads_by_smartview
    conn = Faraday.new(url: 'https://api.close.com/api/v1/') do |faraday|
      faraday.request :authorization, :basic, CLOSE_API_KEY, ''
      faraday.adapter Faraday.default_adapter
    end

    search_query = {
      query: {
        type: 'and',
        queries: [
          { type: 'object_type', object_type: 'lead' },
          {
            type: 'any_of_saved_search',
            saved_search_ids: [SMART_VIEW_ID]
          }
        ]
      },
      _fields: { lead: ['id', 'name', 'status_label'] },
      _limit: 200
    }

    response = conn.post('data/search/', search_query.to_json, 'Content-Type' => 'application/json')
    if response.success?
      JSON.parse(response.body)['data']
    else
      puts "Close API Error: #{response.status}"
      puts "Antwort: #{response.body}"
      []
    end
  end
  

end


