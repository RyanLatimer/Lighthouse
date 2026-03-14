class AccuracyFlaggingService
  FLAG_THRESHOLD = 1000

  def initialize(event)
    @event = event
  end

  # Flags scouting entries whose alliance total deviates from the actual
  # match score by more than FLAG_THRESHOLD points. Unflags entries that
  # were previously auto-flagged but now fall within the threshold (e.g.,
  # after an entry is corrected).
  #
  # Only touches entries with `submitted` or `flagged` status; `rejected`
  # entries are never modified. Returns the number of entries whose status
  # changed.
  def call
    changed_count = 0

    matches_with_scores = @event.matches.with_scores.includes(
      match_alliances: :frc_team,
      scouting_entries: :user
    )

    matches_with_scores.each do |match|
      %w[red blue].each do |color|
        actual_score = color == "red" ? match.red_score : match.blue_score
        next unless actual_score

        # Get the teams on this alliance
        alliance_teams = match.match_alliances.select { |ma| ma.alliance_color == color }
        team_ids = alliance_teams.map(&:frc_team_id)
        next if team_ids.size < 3

        # Find non-rejected scouting entries for all 3 teams in this match
        entries = match.scouting_entries.select do |e|
          !e.rejected? && team_ids.include?(e.frc_team_id)
        end

        entries_by_team = entries.group_by(&:frc_team_id)
        next unless team_ids.all? { |tid| entries_by_team.key?(tid) }

        # Sum total_points from the 3 entries (one per team)
        scouted_total = team_ids.sum do |tid|
          entries_by_team[tid].first.total_points
        end

        alliance_error = (scouted_total - actual_score).abs

        # Collect all alliance entries for status update
        alliance_entries = team_ids.flat_map { |tid| entries_by_team[tid] }

        if alliance_error > FLAG_THRESHOLD
          # Flag submitted entries that exceed the threshold
          alliance_entries.each do |entry|
            next unless entry.submitted?
            entry.update_column(:status, ScoutingEntry.statuses[:flagged])
            changed_count += 1
          end
        else
          # Unflag entries that are now within the threshold
          alliance_entries.each do |entry|
            next unless entry.flagged?
            entry.update_column(:status, ScoutingEntry.statuses[:submitted])
            changed_count += 1
          end
        end
      end
    end

    Rails.logger.info("[AccuracyFlaggingService] Changed #{changed_count} entry statuses for event #{@event.name}")
    changed_count
  end
end
