class LeadsController < ApplicationController
  before_action :authenticate_user!

  CLOSE_API_KEY = ENV["CLOSE_API_KEY"]

  def index
    @current_smart_view_id = params[:smart_view_id] || current_user.smart_view_ids&.first
    @smart_views = fetch_smart_views.select { |smart_view| current_user.smart_view_ids.include?(smart_view["id"]) }
    @leads = fetch_leads_by_smartview(@current_smart_view_id)
    @lead_statuses = fetch_lead_statuses
  end

  def update
    response = conn.put(
      "lead/#{params[:id]}/",
      { description: params[:description], status_id: params[:status_id] }.to_json,
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

  def fetch_leads_by_smartview(smart_view_id)
    return [] unless smart_view_id.present?

    search_query = {
      query: {
        type: 'and',
        queries: [
          { type: 'object_type', object_type: 'lead' },
          { type: 'any_of_saved_search', saved_search_ids: [smart_view_id] }
        ]
      },
      _fields: {
        lead: [
          'id', 'name', 'status_label', 'status_id', 'description',
          'contacts', 'custom.cf_K3ausfM3pWXa7CAMQIpWV0eV7Dqc2IXIuOpiX4Luqa9', 'date_created'
        ]
      },
      _limit: 200
    }

    response = conn.post('data/search/', search_query.to_json, 'Content-Type' => 'application/json')
    if response.success?
      JSON.parse(response.body)['data']
    else
      Rails.logger.error "Close API Error: #{response.status} - #{response.body}"
      []
    end
  end

  def fetch_lead_statuses
    response = conn.get('status/lead/')

    if response.success?
      JSON.parse(response.body)['data']
    else
      Rails.logger.error "Close API Error (statuses): #{response.status} - #{response.body}"
      []
    end
  end

  def fetch_smart_views
    response = conn.get("saved_search/")

    if response.success?
      JSON.parse(response.body)["data"]
    else
      Rails.logger.error "Close API Error (statuses): #{response.status} - #{response.body}"
      []
    end
  end

  def conn
    Faraday.new(url: 'https://api.close.com/api/v1/') do |faraday|
      faraday.request :authorization, :basic, CLOSE_API_KEY, ''
      faraday.adapter Faraday.default_adapter
    end
  end
end
