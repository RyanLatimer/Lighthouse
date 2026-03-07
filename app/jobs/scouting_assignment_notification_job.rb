class ScoutingAssignmentNotificationJob < ApplicationJob
  queue_as :default

  THRESHOLDS = [ 5, 2, 1 ].freeze

  def perform(event_id)
    event = Event.find_by(id: event_id)
    return unless event

    ordered_matches = event.matches.where(comp_level: "qm").ordered.to_a
    return if ordered_matches.empty?

    match_index = ordered_matches.each_with_index.to_h
    current_index = latest_completed_match_index(ordered_matches)
    return unless current_index

    assignments = ScoutingAssignment.includes(:match, :user).where(event_id: event.id)
    shift_start_ids = compute_shift_starts(assignments)

    assignments.find_each do |assignment|
      # Only notify for the first match in each contiguous shift
      next unless shift_start_ids.include?(assignment.id)

      target_index = match_index[assignment.match]
      next if target_index.nil?

      ahead = target_index - current_index
      next unless THRESHOLDS.include?(ahead)

      notified_column = "notified_#{ahead}_at"
      next if assignment.public_send(notified_column).present?

      delivered = PushNotificationService.new(assignment.user).send_assignment_notification!(
        assignment: assignment,
        matches_ahead: ahead
      )
      next unless delivered

      assignment.update_column(notified_column, Time.current)
    end
  end

  private

  def latest_completed_match_index(ordered_matches)
    latest = ordered_matches.rindex { |match| match.red_score.present? && match.blue_score.present? }
    latest || 0
  end

  # Returns a Set of assignment IDs that are the first match in a contiguous
  # block of assignments for each user (i.e. "shift starts").
  def compute_shift_starts(assignments)
    shift_start_ids = Set.new

    assignments.group_by(&:user_id).each do |_user_id, user_assignments|
      sorted = user_assignments.sort_by { |a| a.match.match_number }
      sorted.each_with_index do |assignment, i|
        if i == 0 || assignment.match.match_number != sorted[i - 1].match.match_number + 1
          shift_start_ids.add(assignment.id)
        end
      end
    end

    shift_start_ids
  end
end
