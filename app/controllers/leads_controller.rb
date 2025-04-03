class LeadsController < ApplicationController
  before_action :authenticate_user!

  CLOSE_API_KEY = ENV["CLOSE_API_KEY"]

  def index
    @current_smart_view_id = params[:smart_view_id] || current_user.smart_view_ids&.first
    @leads = fetch_leads_by_smartview(@current_smart_view_id)
    @lead_statuses = fetch_lead_statuses
  end

  def update_description
    lead_id = params[:id]
    new_description = params[:description]

    conn = close_connection

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

  def update_status
    lead_id = params[:id]
    new_status_id = params[:status_id]

    conn = close_connection

    response = conn.put(
      "lead/#{lead_id}/",
      { status_id: new_status_id }.to_json,
      'Content-Type' => 'application/json'
    )

    if response.success?
      updated_lead = fetch_single_lead(lead_id)

      render turbo_stream: turbo_stream.replace(
        "lead_status_#{lead_id}",
        partial: "leads/status",
        locals: { lead: updated_lead, lead_statuses: fetch_lead_statuses }
      )
    else
      Rails.logger.error "Close API Error: #{response.status} - #{response.body}"
      render json: { status: 'error', message: response.body }, status: :unprocessable_entity
    end
  end

  private

  def fetch_leads_by_smartview(smart_view_id)
    return [] unless smart_view_id.present?

    conn = close_connection

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

  def fetch_single_lead(lead_id)
    conn = close_connection
    response = conn.get("lead/#{lead_id}/")

    if response.success?
      JSON.parse(response.body)
    else
      Rails.logger.error "Close API Error (single lead): #{response.status} - #{response.body}"
      nil
    end
  end

  def fetch_lead_statuses
    conn = close_connection

    response = conn.get('status/lead/')

    if response.success?
      JSON.parse(response.body)['data']
    else
      Rails.logger.error "Close API Error (statuses): #{response.status} - #{response.body}"
      []
    end
  end

  def close_connection
    Faraday.new(url: 'https://api.close.com/api/v1/') do |faraday|
      faraday.request :authorization, :basic, CLOSE_API_KEY, ''
      faraday.adapter Faraday.default_adapter
    end
  end
end
