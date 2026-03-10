class UserShiftStatusService
  def initialize(event, user)
    @event = event
    @user = user
  end

  def call
    return { state: :unavailable } if qualification_matches.empty?

    if shift_windows.empty?
      {
        state: :unassigned,
        current_match: current_match
      }
    elsif current_match.nil?
      {
        state: :completed,
        current_match: qualification_matches.last
      }
    elsif (shift = active_shift)
      {
        state: :active,
        current_match: current_match,
        shift_start: shift[:start_match],
        shift_end: shift[:end_match],
        matches_left_in_shift: shift[:end_index] - current_match_index + 1
      }
    elsif (shift = upcoming_shift)
      {
        state: :upcoming,
        current_match: current_match,
        shift_start: shift[:start_match],
        shift_end: shift[:end_match],
        matches_until_start: shift[:start_index] - current_match_index
      }
    else
      {
        state: :completed,
        current_match: current_match
      }
    end
  end

  private

  def qualification_matches
    @qualification_matches ||= @event.matches.where(comp_level: "qm").ordered.to_a
  end

  def qualification_match_by_number
    @qualification_match_by_number ||= qualification_matches.index_by(&:match_number)
  end

  def assignments
    @assignments ||= ScoutingAssignment.where(event: @event, user: @user)
                                       .joins(:match)
                                       .merge(Match.where(comp_level: "qm"))
                                       .includes(:match)
                                       .order("matches.match_number ASC")
                                       .to_a
  end

  def shift_windows
    @shift_windows ||= begin
      match_numbers = assignments.map { |assignment| assignment.match.match_number }.uniq.sort
      if match_numbers.empty?
        []
      else
        shifts = []
        start_number = match_numbers.first
        end_number = match_numbers.first

        match_numbers.drop(1).each do |match_number|
          if match_number == end_number + 1
            end_number = match_number
          else
            shifts << build_shift(start_number, end_number)
            start_number = match_number
            end_number = match_number
          end
        end

        shifts << build_shift(start_number, end_number)
        shifts.compact
      end
    end
  end

  def build_shift(start_number, end_number)
    start_match = qualification_match_by_number[start_number]
    end_match = qualification_match_by_number[end_number]
    return if start_match.nil? || end_match.nil?

    {
      start_match: start_match,
      end_match: end_match,
      start_index: qualification_match_index.fetch(start_match),
      end_index: qualification_match_index.fetch(end_match),
      range: start_number..end_number
    }
  end

  def active_shift
    shift_windows.find { |shift| shift[:range].cover?(current_match.match_number) }
  end

  def upcoming_shift
    shift_windows.find { |shift| shift[:start_index] > current_match_index }
  end

  def current_match
    @current_match ||= begin
      latest_completed_index = qualification_matches.rindex do |match|
        match.red_score.present? && match.blue_score.present?
      end

      if latest_completed_index.nil?
        qualification_matches.first
      else
        qualification_matches[latest_completed_index + 1]
      end
    end
  end

  def current_match_index
    @current_match_index ||= qualification_match_index[current_match]
  end

  def qualification_match_index
    @qualification_match_index ||= qualification_matches.each_with_index.to_h
  end
end
