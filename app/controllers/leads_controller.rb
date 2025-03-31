class LeadsController < ApplicationController
  CLOSE_API_KEY = 'api_6D5d2FMmcNMQqrRmw0o5QB.3oWH6P1b4eX5TW3LpWngOU'
  SMART_VIEW_ID = 'save_7UsYIsBLesxVJmt4cHzQUNuzcbxL2u5l1sUsrvy9yhp'



  def index
    @leads = fetch_leads_by_smartview
  end

  def update_description
  lead_id = params[:id]
  new_description = params[:description]

  conn = Faraday.new(url: 'https://api.close.com/api/v1/') do |faraday|
    faraday.request :authorization, :basic, CLOSE_API_KEY, ''
    faraday.adapter Faraday.default_adapter
  end

  response = conn.put(
    "lead/#{lead_id}/",
    { description: new_description }.to_json,
    'Content-Type' => 'application/json'
  )

  if response.success?
    render json: { status: 'ok' }
  else
    Rails.logger.error "Close API Error: #{response.status} - #{response.body}"
    render json: { status: 'error', message: response.body }, status: :unprocessable_entity
  end
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
      _fields: { lead: ['id', 'name', 'status_label', 'description', 'contacts', 'custom.cf_K3ausfM3pWXa7CAMQIpWV0eV7Dqc2IXIuOpiX4Luqa9', 'date_created', 'custom.cf_95xSZmN3OrCcUBVrU3M0QDn9T2peoKz4q9n1HHV5I1A'] },
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


