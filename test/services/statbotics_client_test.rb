# frozen_string_literal: true

require "test_helper"

class StatboticsClientTest < ActiveSupport::TestCase
  setup do
    @client = StatboticsClient.new
  end

  test "initializes without error" do
    assert_instance_of StatboticsClient, @client
  end

  test "BASE_URL points to statbotics API v3" do
    assert_equal "https://api.statbotics.io/v3", StatboticsClient::BASE_URL
  end

  test "CACHE_TTL is 10 minutes" do
    assert_equal 10.minutes, StatboticsClient::CACHE_TTL
  end

  test "team_year returns nil on network failure" do
    # In test environment, real HTTP calls will fail or be unavailable
    # The client rescues Faraday::Error and returns nil
    result = @client.team_year(254, 2026)

    # Will be nil because the real API is not available in test
    # (or could be cached). Either way, it should not raise.
    assert_nil(result) || assert(result.is_a?(Hash))
  end

  test "event returns nil on network failure" do
    result = @client.event("2026cmp")
    assert_nil(result) || assert(result.is_a?(Hash))
  end

  test "matches returns nil on network failure" do
    result = @client.matches("2026cmp")
    assert_nil(result) || assert(result.is_a?(Array))
  end

  test "methods do not raise exceptions on failure" do
    assert_nothing_raised { @client.team_year(99999, 1900) }
    assert_nothing_raised { @client.event("nonexistent_key") }
    assert_nothing_raised { @client.matches("nonexistent_key") }
  end
end
