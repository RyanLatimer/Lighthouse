class RebuildTeamEventSummariesWithNewColumns < ActiveRecord::Migration[8.1]
  def up
    execute "DROP MATERIALIZED VIEW IF EXISTS team_event_summaries"

    execute <<-SQL
      CREATE MATERIALIZED VIEW team_event_summaries AS
      SELECT
        event_id,
        frc_team_id,
        COUNT(*) AS matches_scouted,

        -- Average fuel made (all phases)
        AVG(
          COALESCE((data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_made')::numeric, 0)
        ) AS avg_fuel_made,

        -- Average fuel missed (all phases)
        AVG(
          COALESCE((data->>'auton_fuel_missed')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_missed')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_missed')::numeric, 0)
        ) AS avg_fuel_missed,

        -- Fuel accuracy percentage (weighted across all entries)
        CASE
          WHEN SUM(
            COALESCE((data->>'auton_fuel_made')::numeric, 0) +
            COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
            COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
            COALESCE((data->>'auton_fuel_missed')::numeric, 0) +
            COALESCE((data->>'teleop_fuel_missed')::numeric, 0) +
            COALESCE((data->>'endgame_fuel_missed')::numeric, 0)
          ) > 0
          THEN ROUND(
            SUM(
              COALESCE((data->>'auton_fuel_made')::numeric, 0) +
              COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
              COALESCE((data->>'endgame_fuel_made')::numeric, 0)
            ) * 100.0 /
            NULLIF(SUM(
              COALESCE((data->>'auton_fuel_made')::numeric, 0) +
              COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
              COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
              COALESCE((data->>'auton_fuel_missed')::numeric, 0) +
              COALESCE((data->>'teleop_fuel_missed')::numeric, 0) +
              COALESCE((data->>'endgame_fuel_missed')::numeric, 0)
            ), 0), 1)
          ELSE 0
        END AS fuel_accuracy_pct,

        -- Average climb points: combined auton climb (15) + endgame climb (10/20/30)
        AVG(
          CASE WHEN (data->>'auton_climb')::boolean THEN 15 ELSE 0 END +
          CASE data->>'endgame_climb'
            WHEN 'L3' THEN 30
            WHEN 'L2' THEN 20
            WHEN 'L1' THEN 10
            ELSE 0
          END
        ) AS avg_climb_points,

        -- Average total points (fuel + auton climb + endgame climb)
        AVG(
          COALESCE((data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
          CASE WHEN (data->>'auton_climb')::boolean THEN 15 ELSE 0 END +
          CASE data->>'endgame_climb'
            WHEN 'L3' THEN 30
            WHEN 'L2' THEN 20
            WHEN 'L1' THEN 10
            ELSE 0
          END
        ) AS avg_total_points,

        -- Standard deviation of total points
        STDDEV_SAMP(
          COALESCE((data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
          CASE WHEN (data->>'auton_climb')::boolean THEN 15 ELSE 0 END +
          CASE data->>'endgame_climb'
            WHEN 'L3' THEN 30
            WHEN 'L2' THEN 20
            WHEN 'L1' THEN 10
            ELSE 0
          END
        ) AS stddev_total_points,

        -- NEW: Average auton points (auton fuel + auton climb bonus)
        AVG(
          COALESCE((data->>'auton_fuel_made')::numeric, 0) +
          CASE WHEN (data->>'auton_climb')::boolean THEN 15 ELSE 0 END
        ) AS avg_auton_points,

        -- NEW: Average defense rating (1-5, excluding unrated entries where value is 0 or null)
        AVG(NULLIF(COALESCE((data->>'defense_rating')::numeric, 0), 0)) AS avg_defense_rating,

        MAX(updated_at) AS last_updated

      FROM scouting_entries
      WHERE status = 0
      GROUP BY event_id, frc_team_id
      WITH NO DATA
    SQL

    add_index :team_event_summaries, [ :event_id, :frc_team_id ],
              unique: true, name: "idx_team_event_summaries"

    # Populate the view
    execute "REFRESH MATERIALIZED VIEW team_event_summaries"
  end

  def down
    execute "DROP MATERIALIZED VIEW IF EXISTS team_event_summaries"

    # Recreate the original view without the new columns
    execute <<-SQL
      CREATE MATERIALIZED VIEW team_event_summaries AS
      SELECT
        event_id,
        frc_team_id,
        COUNT(*) AS matches_scouted,
        AVG(
          COALESCE((data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_made')::numeric, 0)
        ) AS avg_fuel_made,
        AVG(
          COALESCE((data->>'auton_fuel_missed')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_missed')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_missed')::numeric, 0)
        ) AS avg_fuel_missed,
        CASE
          WHEN SUM(
            COALESCE((data->>'auton_fuel_made')::numeric, 0) +
            COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
            COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
            COALESCE((data->>'auton_fuel_missed')::numeric, 0) +
            COALESCE((data->>'teleop_fuel_missed')::numeric, 0) +
            COALESCE((data->>'endgame_fuel_missed')::numeric, 0)
          ) > 0
          THEN ROUND(
            SUM(
              COALESCE((data->>'auton_fuel_made')::numeric, 0) +
              COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
              COALESCE((data->>'endgame_fuel_made')::numeric, 0)
            ) * 100.0 /
            NULLIF(SUM(
              COALESCE((data->>'auton_fuel_made')::numeric, 0) +
              COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
              COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
              COALESCE((data->>'auton_fuel_missed')::numeric, 0) +
              COALESCE((data->>'teleop_fuel_missed')::numeric, 0) +
              COALESCE((data->>'endgame_fuel_missed')::numeric, 0)
            ), 0), 1)
          ELSE 0
        END AS fuel_accuracy_pct,
        AVG(
          CASE data->>'endgame_climb'
            WHEN 'L3' THEN 30
            WHEN 'L2' THEN 20
            WHEN 'L1' THEN 10
            ELSE 0
          END
        ) AS avg_climb_points,
        AVG(
          COALESCE((data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
          CASE WHEN (data->>'auton_climb')::boolean THEN 15 ELSE 0 END +
          CASE data->>'endgame_climb'
            WHEN 'L3' THEN 30
            WHEN 'L2' THEN 20
            WHEN 'L1' THEN 10
            ELSE 0
          END
        ) AS avg_total_points,
        STDDEV_SAMP(
          COALESCE((data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
          CASE WHEN (data->>'auton_climb')::boolean THEN 15 ELSE 0 END +
          CASE data->>'endgame_climb'
            WHEN 'L3' THEN 30
            WHEN 'L2' THEN 20
            WHEN 'L1' THEN 10
            ELSE 0
          END
        ) AS stddev_total_points,
        MAX(updated_at) AS last_updated
      FROM scouting_entries
      WHERE status = 0
      GROUP BY event_id, frc_team_id
      WITH NO DATA
    SQL

    add_index :team_event_summaries, [ :event_id, :frc_team_id ],
              unique: true, name: "idx_team_event_summaries"
  end
end
