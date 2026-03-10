# frozen_string_literal: true

class ScoutableMatchesQuery
  def initialize(event, reference_time: Time.current)
    @event = event
    @reference_time = reference_time
  end

  def live
    return [] if event_finished?

    loaded_matches.select { |match| match.upcoming?(@reference_time) }
  end

  def replay
    loaded_matches.select { |match| match.occurred?(@reference_time) }
                  .sort_by { |match| [ match.best_known_time || Time.at(0), match.id ] }
                  .reverse
  end

  private

  def event_finished?
    @event.end_date.present? && @event.end_date < @reference_time.to_date
  end

  def loaded_matches
    @loaded_matches ||= @event.matches.includes(match_alliances: :frc_team).ordered.to_a
  end
end
