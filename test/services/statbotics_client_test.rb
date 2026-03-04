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

  test "CACHE_TTL is 1 hour" do
    assert_equal 1.hour, StatboticsClient::CACHE_TTL
  end

  test "team_year returns nil or a hash" do
    result = @client.team_year(254, 2026)
    assert(result.nil? || result.is_a?(Hash), "Expected nil or Hash, got #{result.class}")
  end

  test "event returns nil or a hash" do
    result = @client.event("2026cmp")
    assert(result.nil? || result.is_a?(Hash), "Expected nil or Hash, got #{result.class}")
  end

  test "matches returns nil or an array" do
    result = @client.matches("2026cmp")
    assert(result.nil? || result.is_a?(Array), "Expected nil or Array, got #{result.class}")
  end

  test "methods do not raise exceptions on failure" do
    assert_nothing_raised { @client.team_year(99999, 1900) }
    assert_nothing_raised { @client.event("nonexistent_key") }
    assert_nothing_raised { @client.matches("nonexistent_key") }
  end
end
