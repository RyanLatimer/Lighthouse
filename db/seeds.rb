# frozen_string_literal: true

# Seeds are for development/test only. Skip in production unless explicitly requested.
if Rails.env.production? && !ENV["FORCE_SEED"]
  puts "Skipping seeds in production. Set FORCE_SEED=1 to override."
  return
end

puts "Seeding database..."

# --- Default Organization ---
org = Organization.find_or_create_by!(slug: "default") do |o|
  o.name = "Default Organization"
  o.team_number = 1234
end
puts "  Organization: #{org.name} (slug: #{org.slug})"

# --- Game Configuration for 2026 REBUILT ---
game_config = GameConfig.find_or_create_by!(year: 2026) do |gc|
  gc.game_name = "REBUILT presented by Haas"
  gc.active = true
  gc.organization = org
  gc.config = {
    year: 2026,
    game_name: "REBUILT presented by Haas",
    simple_shooting_mode: true,
    scoring: {
      fuel_point_value: 1,
      auton_climb_points: 15,
      climb_points: { "None" => 0, "L1" => 10, "L2" => 20, "L3" => 30 }
    },
    phases: {
      auton: {
        fields: [
          { key: "auton_fuel_made", type: "counter", label: "Fuel Made", color: "green" },
          { key: "auton_fuel_missed", type: "counter", label: "Fuel Missed", color: "red" },
          { key: "auton_climb", type: "toggle", label: "Auton Climb (15 pts)", default: false }
        ],
        actions: [
          { key: "bump", label: "Bump", icon: "collision" },
          { key: "trench", label: "Trench", icon: "road" },
          { key: "intake", label: "Intake", icon: "download" }
        ]
      },
      teleop: {
        fields: [
          { key: "teleop_fuel_made", type: "counter", label: "Fuel Made", color: "green" },
          { key: "teleop_fuel_missed", type: "counter", label: "Fuel Missed", color: "red" }
        ]
      },
      endgame: {
        fields: [
          { key: "endgame_fuel_made", type: "counter", label: "Fuel Made", color: "green" },
          { key: "endgame_fuel_missed", type: "counter", label: "Fuel Missed", color: "red" },
          { key: "endgame_climb", type: "select", label: "Climb Level", options: %w[None L1 L2 L3], default: "None" }
        ]
      }
    },
    auton_actions_tracked: %w[bump trench intake]
  }
end
puts "  Game config: #{game_config.game_name} (#{game_config.year})"

# --- Admin User ---
admin = User.find_or_create_by!(email: "admin@lighthouse.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.first_name = "Admin"
  u.last_name = "User"
  u.team_number = 1234
end
admin.add_role(:admin) unless admin.has_role?(:admin)

# Ensure admin has a membership in the default organization
Membership.find_or_create_by!(user: admin, organization: org) do |m|
  m.role = :owner
end
puts "  Admin user: #{admin.email} (role: admin, org membership: owner)"

# --- Scout User ---
scout = User.find_or_create_by!(email: "scout@lighthouse.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.first_name = "Scout"
  u.last_name = "User"
  u.team_number = 1234
end
scout.add_role(:scout) unless scout.has_role?(:scout)

# Ensure scout has a membership in the default organization
Membership.find_or_create_by!(user: scout, organization: org) do |m|
  m.role = :scout
end
puts "  Scout user: #{scout.email} (role: scout, org membership: scout)"

# =============================================================================
# TEST EVENT: Fully populated with realistic data
# =============================================================================
puts ""
puts "--- Populating test event with full data ---"

# --- Additional scout users for varied scouting data ---
scout2 = User.find_or_create_by!(email: "scout2@lighthouse.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.first_name = "Maya"
  u.last_name = "Chen"
  u.team_number = 1234
end
scout2.add_role(:scout) unless scout2.has_role?(:scout)
Membership.find_or_create_by!(user: scout2, organization: org) { |m| m.role = :scout }

scout3 = User.find_or_create_by!(email: "scout3@lighthouse.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.first_name = "Jake"
  u.last_name = "Torres"
  u.team_number = 1234
end
scout3.add_role(:scout) unless scout3.has_role?(:scout)
Membership.find_or_create_by!(user: scout3, organization: org) { |m| m.role = :scout }

analysts = [ admin, scout, scout2, scout3 ]

# --- 12 FRC Teams ---
team_data = [
  { team_number: 254,  nickname: "The Cheesy Poofs",  city: "San Jose",     state_prov: "CA", country: "USA", rookie_year: 1999 },
  { team_number: 1678, nickname: "Citrus Circuits",    city: "Davis",        state_prov: "CA", country: "USA", rookie_year: 2005 },
  { team_number: 118,  nickname: "Robonauts",          city: "Houston",      state_prov: "TX", country: "USA", rookie_year: 1997 },
  { team_number: 2056, nickname: "OP Robotics",        city: "Mississauga",  state_prov: "ON", country: "Canada", rookie_year: 2007 },
  { team_number: 971,  nickname: "Spartan Robotics",   city: "Mountain View", state_prov: "CA", country: "USA", rookie_year: 2002 },
  { team_number: 148,  nickname: "Robowranglers",      city: "Greenville",   state_prov: "TX", country: "USA", rookie_year: 1995 },
  { team_number: 2910, nickname: "Jack in the Bot",    city: "Sammamish",    state_prov: "WA", country: "USA", rookie_year: 2009 },
  { team_number: 4414, nickname: "HighTide",           city: "Ventura",      state_prov: "CA", country: "USA", rookie_year: 2012 },
  { team_number: 6328, nickname: "Mechanical Advantage", city: "Littleton", state_prov: "MA", country: "USA", rookie_year: 2017 },
  { team_number: 1323, nickname: "MadTown Robotics",   city: "Madera",       state_prov: "CA", country: "USA", rookie_year: 2004 },
  { team_number: 3310, nickname: "Black Hawk Robotics", city: "Pearland",    state_prov: "TX", country: "USA", rookie_year: 2010 },
  { team_number: 5940, nickname: "BREAD",              city: "Palm Beach",   state_prov: "FL", country: "USA", rookie_year: 2016 }
]

teams = team_data.map do |td|
  FrcTeam.find_or_create_by!(team_number: td[:team_number]) do |t|
    t.nickname = td[:nickname]
    t.city = td[:city]
    t.state_prov = td[:state_prov]
    t.country = td[:country]
    t.rookie_year = td[:rookie_year]
  end
end
puts "  Teams: #{teams.size} created/found"

# --- Test Event ---
event = Event.find_or_create_by!(tba_key: "2026txhou") do |e|
  e.name = "Houston Regional"
  e.year = 2026
  e.event_type = 0
  e.start_date = Date.new(2026, 3, 5)
  e.end_date = Date.new(2026, 3, 7)
  e.city = "Houston"
  e.state_prov = "TX"
  e.country = "USA"
  e.week = 1
  e.organization = org
end
puts "  Event: #{event.name} (#{event.tba_key})"

# --- Link teams to event ---
teams.each do |team|
  EventTeam.find_or_create_by!(event: event, frc_team: team)
end
puts "  EventTeams: #{EventTeam.where(event: event).count} linked"

# --- Create 12 qualification matches with full 3v3 alliances ---
# Each team plays ~6 matches (like a real regional schedule)
match_assignments = [
  # [match#, [red1, red2, red3], [blue1, blue2, blue3]] (by team index 0-11)
  [ 1,  [ 0, 3, 6 ],   [ 1, 4, 7 ] ],
  [ 2,  [ 2, 5, 8 ],   [ 9, 10, 11 ] ],
  [ 3,  [ 0, 4, 8 ],   [ 2, 6, 10 ] ],
  [ 4,  [ 1, 5, 9 ],   [ 3, 7, 11 ] ],
  [ 5,  [ 0, 5, 10 ],  [ 1, 6, 11 ] ],
  [ 6,  [ 2, 3, 9 ],   [ 4, 8, 7 ] ],
  [ 7,  [ 0, 7, 9 ],   [ 2, 4, 11 ] ],
  [ 8,  [ 1, 3, 8 ],   [ 5, 6, 10 ] ],
  [ 9,  [ 0, 2, 11 ],  [ 1, 9, 8 ] ],
  [ 10, [ 3, 4, 5 ],   [ 6, 7, 10 ] ],
  [ 11, [ 0, 1, 10 ],  [ 3, 8, 11 ] ],
  [ 12, [ 2, 7, 9 ],   [ 4, 5, 6 ] ]
]

matches = match_assignments.map do |match_num, red_indices, blue_indices|
  m = Match.find_or_create_by!(event: event, tba_key: "2026txhou_qm#{match_num}") do |match|
    match.comp_level = "qm"
    match.match_number = match_num
    match.set_number = 1
    match.scheduled_time = event.start_date.to_datetime + 9.hours + (match_num * 8).minutes
  end

  red_indices.each_with_index do |ti, station|
    MatchAlliance.find_or_create_by!(match: m, frc_team: teams[ti]) do |ma|
      ma.alliance_color = "red"
      ma.station = station + 1
    end
  end

  blue_indices.each_with_index do |ti, station|
    MatchAlliance.find_or_create_by!(match: m, frc_team: teams[ti]) do |ma|
      ma.alliance_color = "blue"
      ma.station = station + 1
    end
  end

  m
end
puts "  Matches: #{matches.size} with #{MatchAlliance.where(match_id: matches.map(&:id)).count} alliances"

# --- Team performance profiles (for realistic scouting data) ---
# Each team has a "skill level" that determines their scoring range.
# [avg_auton_made, avg_teleop_made, avg_endgame_made, miss_rate, climb_level_weights, auton_climb_pct]
profiles = {
  254  => { auton: 6, teleop: 15, endgame: 3, miss_pct: 0.10, climb_wt: { "L3" => 0.8, "L2" => 0.15, "L1" => 0.05 }, auton_climb: 0.9 },
  1678 => { auton: 5, teleop: 14, endgame: 2, miss_pct: 0.12, climb_wt: { "L3" => 0.7, "L2" => 0.2, "L1" => 0.1 }, auton_climb: 0.85 },
  118  => { auton: 5, teleop: 12, endgame: 2, miss_pct: 0.15, climb_wt: { "L3" => 0.6, "L2" => 0.3, "L1" => 0.1 }, auton_climb: 0.8 },
  2056 => { auton: 4, teleop: 11, endgame: 2, miss_pct: 0.18, climb_wt: { "L3" => 0.4, "L2" => 0.4, "L1" => 0.2 }, auton_climb: 0.7 },
  971  => { auton: 5, teleop: 13, endgame: 2, miss_pct: 0.14, climb_wt: { "L3" => 0.65, "L2" => 0.25, "L1" => 0.1 }, auton_climb: 0.75 },
  148  => { auton: 4, teleop: 10, endgame: 1, miss_pct: 0.20, climb_wt: { "L2" => 0.5, "L1" => 0.3, "None" => 0.2 }, auton_climb: 0.5 },
  2910 => { auton: 4, teleop: 12, endgame: 2, miss_pct: 0.16, climb_wt: { "L3" => 0.5, "L2" => 0.35, "L1" => 0.15 }, auton_climb: 0.65 },
  4414 => { auton: 3, teleop: 9,  endgame: 1, miss_pct: 0.22, climb_wt: { "L2" => 0.4, "L1" => 0.4, "None" => 0.2 }, auton_climb: 0.4 },
  6328 => { auton: 5, teleop: 13, endgame: 2, miss_pct: 0.13, climb_wt: { "L3" => 0.6, "L2" => 0.3, "L1" => 0.1 }, auton_climb: 0.8 },
  1323 => { auton: 3, teleop: 8,  endgame: 1, miss_pct: 0.25, climb_wt: { "L1" => 0.5, "None" => 0.3, "L2" => 0.2 }, auton_climb: 0.3 },
  3310 => { auton: 3, teleop: 7,  endgame: 1, miss_pct: 0.28, climb_wt: { "L1" => 0.4, "None" => 0.4, "L2" => 0.2 }, auton_climb: 0.2 },
  5940 => { auton: 2, teleop: 6,  endgame: 0, miss_pct: 0.30, climb_wt: { "None" => 0.5, "L1" => 0.4, "L2" => 0.1 }, auton_climb: 0.1 }
}

def weighted_pick(weights)
  r = rand
  cumulative = 0.0
  weights.each do |value, weight|
    cumulative += weight
    return value if r <= cumulative
  end
  weights.keys.last
end

def vary(value, pct = 0.3)
  delta = (value * pct).ceil
  [ value + rand(-delta..delta), 0 ].max
end

# --- Create scouting entries for every team in every match they play ---
scouting_count = 0
match_assignments.each_with_index do |(match_num, red_indices, blue_indices), mi|
  all_team_indices = red_indices + blue_indices
  match = matches[mi]

  all_team_indices.each do |ti|
    team = teams[ti]
    profile = profiles[team.team_number]

    # Each match gets 1-2 scouts reporting
    num_scouts = rand(1..2)
    scouts_for_match = analysts.sample(num_scouts)

    scouts_for_match.each do |scouter|
      auton_made = vary(profile[:auton])
      auton_missed = (auton_made * profile[:miss_pct] / (1.0 - profile[:miss_pct])).round + rand(0..1)
      teleop_made = vary(profile[:teleop])
      teleop_missed = (teleop_made * profile[:miss_pct] / (1.0 - profile[:miss_pct])).round + rand(0..2)
      endgame_made = vary(profile[:endgame], 0.5)
      endgame_missed = rand(0..1)
      climb = weighted_pick(profile[:climb_wt])
      auton_climb = rand < profile[:auton_climb]
      defense = rand(1..5)

      entry = ScoutingEntry.find_or_create_by!(
        event: event, frc_team: team, match: match, user: scouter
      ) do |se|
        se.organization = org
        se.status = :submitted
        se.data = {
          "auton_fuel_made" => auton_made,
          "auton_fuel_missed" => auton_missed,
          "teleop_fuel_made" => teleop_made,
          "teleop_fuel_missed" => teleop_missed,
          "endgame_fuel_made" => endgame_made,
          "endgame_fuel_missed" => endgame_missed,
          "endgame_climb" => climb,
          "auton_climb" => auton_climb,
          "defense_rating" => defense,
          "auton_actions" => [
            { "action" => "Mobility", "timestamp" => Time.now.to_i },
            auton_made > 3 ? { "action" => "Preload", "timestamp" => Time.now.to_i } : nil
          ].compact
        }
        se.notes = [
          "Solid performance overall.",
          "Struggled with intake consistency.",
          "Great driver, very aggressive.",
          "Robot had a brief mechanical issue mid-match.",
          "Defense played in teleop, limiting scoring.",
          "Excellent autonomous routine.",
          "Consistent scorer, good climb.",
          nil
        ].sample
      end
      scouting_count += 1
    end
  end
end
puts "  Scouting entries: #{scouting_count}"

# --- Pit scouting entries for every team ---
drivetrains = %w[Swerve Swerve Swerve Tank Mecanum Swerve Swerve Tank Swerve Tank Tank Mecanum]
pit_count = 0
teams.each_with_index do |team, i|
  profile = profiles[team.team_number]
  PitScoutingEntry.find_or_create_by!(event: event, frc_team: team, user: analysts.sample) do |pe|
    pe.organization = org
    pe.status = :submitted
    pe.data = {
      "drivetrain" => drivetrains[i],
      "robot_width" => (26 + rand(0..8)).to_s,
      "robot_length" => (28 + rand(0..6)).to_s,
      "robot_height" => (36 + rand(0..18)).to_s,
      "robot_weight" => (110 + rand(0..15)).to_s,
      "mechanisms" => ([ "Intake", "Shooter", "Climber" ] + (rand < 0.5 ? [ "Elevator" ] : []) + (rand < 0.3 ? [ "Turret" ] : [])),
      "auto_capabilities" => ([ "Leave", "Scoring" ] + (profile[:auton_climb] > 0.5 ? [ "Climbing" ] : []) + (profile[:auton] > 4 ? [ "Multi-piece" ] : [])),
      "strengths" => [ "Fast cycle time", "Reliable climber", "Strong defense", "Accurate shooter", "Flexible autonomous" ].sample(2).join(". ") + ".",
      "weaknesses" => [ "Occasional intake jams", "Slow to recover from defense", "Limited auto", "Tippy when pushed", "Inconsistent climb" ].sample(1).first + "."
    }
    pe.notes = "Pit scouted at #{event.name}. Team was cooperative and well-organized."
  end
  pit_count += 1
end
puts "  Pit scouting entries: #{pit_count}"

# --- Refresh materialized view so summaries compute ---
puts "  Refreshing team_event_summaries materialized view..."
TeamEventSummary.refresh!
summary_count = TeamEventSummary.where(event: event).count
puts "  Team summaries: #{summary_count}"

# --- Generate predictions ---
puts "  Generating predictions..."
begin
  prediction_count = PredictionService.new(event, org).generate_all!
  puts "  Predictions: #{prediction_count} generated"
rescue => e
  puts "  Predictions: failed (#{e.message}) -- this is OK if Statbotics is unreachable"
  # Fallback: create scouting-only predictions manually if the service fails
end

# --- Pick list ---
ranked_teams = TeamEventSummary.where(event: event).order(avg_total_points: :desc).pluck(:frc_team_id)
PickList.find_or_create_by!(event: event, user: admin, name: "Houston Regional Draft Board") do |pl|
  pl.organization = org
  pl.entries = ranked_teams
end
puts "  Pick list: created with #{ranked_teams.size} teams"

# --- Reports ---
Report.find_or_create_by!(event: event, user: admin, name: "Top Scorers") do |r|
  r.organization = org
  r.config = {
    "metrics" => [ "avg_total_points", "fuel_accuracy_pct", "avg_climb_points" ],
    "filters" => { "min_matches" => 2 },
    "sort_by" => "avg_total_points",
    "sort_dir" => "desc",
    "chart_type" => "bar"
  }
end

Report.find_or_create_by!(event: event, user: admin, name: "Accuracy Report") do |r|
  r.organization = org
  r.config = {
    "metrics" => [ "fuel_accuracy_pct", "avg_fuel_made", "avg_fuel_missed" ],
    "filters" => { "min_matches" => 2 },
    "sort_by" => "fuel_accuracy_pct",
    "sort_dir" => "desc",
    "chart_type" => "bar"
  }
end
puts "  Reports: 2 created"

# --- Data conflicts (simulate a disagreement between scouts) ---
conflict_match = matches.first
conflict_team = teams[0] # team 254
DataConflict.find_or_create_by!(
  event: event,
  frc_team: conflict_team,
  match: conflict_match,
  field_name: "endgame_climb"
) do |dc|
  dc.organization = org
  dc.values = { scout.id.to_s => "L3", scout2.id.to_s => "L2" }
  dc.resolved = false
end

DataConflict.find_or_create_by!(
  event: event,
  frc_team: teams[1], # team 1678
  match: matches[1],
  field_name: "auton_climb"
) do |dc|
  dc.organization = org
  dc.values = { scout.id.to_s => "true", scout3.id.to_s => "false" }
  dc.resolved = false
end
puts "  Data conflicts: 2 created"

# --- Summary ---
puts ""
puts "Seed complete!"
puts "  Organizations: #{Organization.count}"
puts "  Game configs: #{GameConfig.count}"
puts "  Users: #{User.count}"
puts "  Memberships: #{Membership.count}"
puts "  Events: #{Event.count}"
puts "  Teams: #{FrcTeam.count}"
puts "  Matches: #{Match.count}"
puts "  Match alliances: #{MatchAlliance.count}"
puts "  Scouting entries: #{ScoutingEntry.count}"
puts "  Pit scouting entries: #{PitScoutingEntry.count}"
puts "  Team summaries: #{TeamEventSummary.count}"
puts "  Predictions: #{Prediction.count}"
puts "  Pick lists: #{PickList.count}"
puts "  Reports: #{Report.count}"
puts "  Data conflicts: #{DataConflict.count}"
