ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Ensure the team_event_summaries materialized view exists in the test database.
# schema.rb cannot represent materialized views, so we create it on demand.
def ensure_team_event_summaries_view!
  ActiveRecord::Base.connection.execute(<<~SQL)
    CREATE MATERIALIZED VIEW IF NOT EXISTS team_event_summaries AS
    SELECT
      se.event_id,
      se.frc_team_id,
      COUNT(*) AS matches_scouted,
      AVG(COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((se.data->>'endgame_fuel_made')::numeric, 0)) AS avg_fuel_made,
      AVG(COALESCE((se.data->>'auton_fuel_missed')::numeric, 0) +
          COALESCE((se.data->>'teleop_fuel_missed')::numeric, 0) +
          COALESCE((se.data->>'endgame_fuel_missed')::numeric, 0)) AS avg_fuel_missed,
      CASE
        WHEN SUM(COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
                 COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
                 COALESCE((se.data->>'endgame_fuel_made')::numeric, 0) +
                 COALESCE((se.data->>'auton_fuel_missed')::numeric, 0) +
                 COALESCE((se.data->>'teleop_fuel_missed')::numeric, 0) +
                 COALESCE((se.data->>'endgame_fuel_missed')::numeric, 0)) > 0
        THEN
          ROUND(
            SUM(COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
                COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
                COALESCE((se.data->>'endgame_fuel_made')::numeric, 0)) * 100.0 /
            NULLIF(SUM(COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
                       COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
                       COALESCE((se.data->>'endgame_fuel_made')::numeric, 0) +
                       COALESCE((se.data->>'auton_fuel_missed')::numeric, 0) +
                       COALESCE((se.data->>'teleop_fuel_missed')::numeric, 0) +
                       COALESCE((se.data->>'endgame_fuel_missed')::numeric, 0)), 0),
            1)
        ELSE 0
      END AS fuel_accuracy_pct,
      AVG(CASE
        WHEN se.data->>'endgame_climb' = 'L3' THEN 30
        WHEN se.data->>'endgame_climb' = 'L2' THEN 20
        WHEN se.data->>'endgame_climb' = 'L1' THEN 10
        ELSE 0
      END) AS avg_climb_points,
      AVG(
        COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
        COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
        COALESCE((se.data->>'endgame_fuel_made')::numeric, 0) +
        CASE WHEN (se.data->>'auton_climb')::boolean THEN 10 ELSE 0 END +
        CASE
          WHEN se.data->>'endgame_climb' = 'L3' THEN 30
          WHEN se.data->>'endgame_climb' = 'L2' THEN 20
          WHEN se.data->>'endgame_climb' = 'L1' THEN 10
          ELSE 0
        END
      ) AS avg_total_points,
      STDDEV_SAMP(
        COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
        COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
        COALESCE((se.data->>'endgame_fuel_made')::numeric, 0) +
        CASE WHEN (se.data->>'auton_climb')::boolean THEN 10 ELSE 0 END +
        CASE
          WHEN se.data->>'endgame_climb' = 'L3' THEN 30
          WHEN se.data->>'endgame_climb' = 'L2' THEN 20
          WHEN se.data->>'endgame_climb' = 'L1' THEN 10
          ELSE 0
        END
      ) AS stddev_total_points,
      MAX(se.updated_at) AS last_updated
    FROM scouting_entries se
    WHERE se.status = 0
    GROUP BY se.event_id, se.frc_team_id
    WITH DATA;
  SQL

  unless ActiveRecord::Base.connection.index_name_exists?("team_event_summaries", "idx_team_event_summaries")
    ActiveRecord::Base.connection.execute(
      "CREATE UNIQUE INDEX idx_team_event_summaries ON team_event_summaries (event_id, frc_team_id);"
    )
  end
rescue ActiveRecord::StatementInvalid
  # View already exists
end

# Create the view once at boot (covers single-process test runs)
ensure_team_event_summaries_view!

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Create the view in each parallel worker's database
    parallelize_setup do |_worker|
      ensure_team_event_summaries_view!
    end
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  private

  # Sign in a user via Devise. After sign_in, the session is available
  # on the next request. Use select_event to pick an event after signing in.
  def sign_in_as(user)
    sign_in user
    user
  end

  # Selects an event by POSTing to the select endpoint, which sets the session.
  def select_event(event)
    post select_event_path(event)
  end

  # Switches to an organization by POSTing to the switch endpoint.
  def switch_organization(org)
    post switch_organization_path(org)
  end
end
