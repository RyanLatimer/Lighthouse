module ScoutingAssignmentsHelper
  def timeline_coverage_classes(count)
    return "bg-red-500/10 text-red-300 border-red-500/30" if count < 3
    return "bg-amber-500/10 text-amber-300 border-amber-500/30" if count > 3

    "bg-emerald-500/10 text-emerald-300 border-emerald-500/30"
  end

  def coverage_label(count)
    "#{count}/3"
  end
end
