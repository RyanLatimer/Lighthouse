# frozen_string_literal: true

class StatboticsClient
  BASE_URL = "https://api.statbotics.io/v3"
  CACHE_TTL = 1.hour

  def initialize
    @conn = build_connection
  end

  # GET /team_year/{team}/{year}
  # Returns EPA data for a team in a given year.
  def team_year(team_number, year)
    cached_get("statbotics:team_year:#{team_number}:#{year}", "/team_year/#{team_number}/#{year}")
  end

  # GET /team_events?event={event_key}
  # Returns EPA + record for ALL teams at an event in a single request.
  def team_events(event_key)
    cached_get("statbotics:team_events:#{event_key}", "/team_events", event: event_key)
  end

  # GET /event/{event_key}
  # Returns event-level EPA and prediction data.
  def event(event_key)
    cached_get("statbotics:event:#{event_key}", "/event/#{event_key}")
  end

  # GET /matches?event={event_key}
  # Returns match predictions and results for an event.
  def matches(event_key)
    cached_get("statbotics:matches:#{event_key}", "/matches", event: event_key)
  end

  private

  def build_connection
    Faraday.new(url: BASE_URL) do |f|
      f.headers["Accept"] = "application/json"
      f.request :retry, max: 3, interval: 0.5, backoff_factor: 2,
                        exceptions: [ Faraday::TimeoutError, Faraday::ConnectionFailed ]
      f.response :json, parser_options: { symbolize_names: false }
      f.adapter Faraday.default_adapter
    end
  end

  def cached_get(cache_key, path, params = {})
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      response = @conn.get(path, params)

      if response.success?
        response.body
      else
        Rails.logger.warn("[StatboticsClient] #{path} returned #{response.status}: #{response.body}")
        nil
      end
    end
  rescue Faraday::Error => e
    Rails.logger.error("[StatboticsClient] Request to #{path} failed: #{e.message}")
    nil
  end
end
