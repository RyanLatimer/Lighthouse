# frozen_string_literal: true

class TbaClient
  BASE_URL = "https://www.thebluealliance.com/api/v3"
  CACHE_TTL = 5.minutes

  def initialize(api_key: ENV["TBA_API_KEY"])
    @api_key = api_key
    @conn = build_connection
  end

  # GET /event/{event_key}
  def event(event_key)
    cached_get("tba:event:#{event_key}", "/event/#{event_key}")
  end

  # GET /event/{event_key}/teams
  def event_teams(event_key)
    cached_get("tba:event_teams:#{event_key}", "/event/#{event_key}/teams")
  end

  # GET /event/{event_key}/matches
  def event_matches(event_key)
    cached_get("tba:event_matches:#{event_key}", "/event/#{event_key}/matches")
  end

  # GET /team/{team_key}
  def team(team_key)
    cached_get("tba:team:#{team_key}", "/team/#{team_key}")
  end

  # GET /event/{event_key}/rankings
  def event_rankings(event_key)
    cached_get("tba:event_rankings:#{event_key}", "/event/#{event_key}/rankings")
  end

  private

  def build_connection
    Faraday.new(url: BASE_URL) do |f|
      f.headers["X-TBA-Auth-Key"] = @api_key
      f.headers["Accept"] = "application/json"
      f.request :retry, max: 3, interval: 0.5, backoff_factor: 2,
                        exceptions: [ Faraday::TimeoutError, Faraday::ConnectionFailed ]
      f.response :json, parser_options: { symbolize_names: false }
      f.adapter Faraday.default_adapter
    end
  end

  def cached_get(cache_key, path)
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      response = @conn.get("#{BASE_URL}#{path}")

      if response.success?
        response.body
      else
        Rails.logger.warn("[TbaClient] #{path} returned #{response.status}: #{response.body}")
        nil
      end
    end
  rescue Faraday::Error => e
    Rails.logger.error("[TbaClient] Request to #{path} failed: #{e.message}")
    nil
  end
end
