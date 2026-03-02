class ExportsController < ApplicationController
  before_action :require_event!

  def csv
    authorize :export, :csv?

    entries = ScoutingEntry.where(event: current_event).includes(:user, :frc_team, :match)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << %w[ID Match Team Scout Status TotalPoints FuelAccuracy Notes CreatedAt]

      entries.find_each do |entry|
        csv << [
          entry.id,
          entry.match&.display_name,
          entry.frc_team.team_number,
          entry.user.full_name,
          entry.status,
          entry.total_points,
          entry.fuel_accuracy,
          entry.notes,
          entry.created_at.iso8601
        ]
      end
    end

    send_data csv_data,
              filename: "#{current_event.tba_key}_scouting_data_#{Date.current}.csv",
              type: "text/csv"
  end

  def pdf
    authorize :export, :pdf?

    pdf_data = ExportService.new(current_event).to_pdf

    send_data pdf_data,
              filename: "#{current_event.tba_key}_scouting_report_#{Date.current}.pdf",
              type: "application/pdf"
  end

  def excel
    authorize :export, :excel?

    excel_data = ExcelExportService.new(current_event).generate

    send_data excel_data,
              filename: "#{current_event.tba_key}_scouting_data_#{Date.current}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def json
    authorize :export, :json?

    entries = ScoutingEntry.where(event: current_event).includes(:user, :frc_team, :match)
    summaries = TeamEventSummary.where(event: current_event).order(avg_total_points: :desc)
    pit_entries = PitScoutingEntry.where(event: current_event).includes(:frc_team, :user)

    data = {
      event: {
        name: current_event.name,
        tba_key: current_event.tba_key,
        year: current_event.year,
        start_date: current_event.start_date,
        end_date: current_event.end_date,
        exported_at: Time.current.iso8601
      },
      team_summaries: summaries.includes(:frc_team).map do |s|
        {
          team_number: s.frc_team.team_number,
          nickname: s.frc_team.nickname,
          avg_total_points: s.avg_total_points.to_f.round(2),
          avg_fuel_made: s.avg_fuel_made.to_f.round(2),
          avg_fuel_missed: s.avg_fuel_missed.to_f.round(2),
          fuel_accuracy_pct: s.fuel_accuracy_pct.to_f.round(1),
          avg_climb_points: s.avg_climb_points.to_f.round(2),
          stddev_total_points: s.stddev_total_points.to_f.round(2),
          matches_scouted: s.matches_scouted
        }
      end,
      scouting_entries: entries.map do |entry|
        {
          id: entry.id,
          match: entry.match&.display_name,
          team_number: entry.frc_team.team_number,
          scout: entry.user.full_name,
          status: entry.status,
          total_points: entry.total_points,
          fuel_accuracy: entry.fuel_accuracy,
          data: entry.data,
          notes: entry.notes,
          created_at: entry.created_at.iso8601
        }
      end,
      pit_scouting: pit_entries.map do |entry|
        {
          team_number: entry.frc_team.team_number,
          scout: entry.user.full_name,
          data: entry.data,
          notes: entry.notes,
          created_at: entry.created_at.iso8601
        }
      end
    }

    send_data data.to_json,
              filename: "#{current_event.tba_key}_full_export_#{Date.current}.json",
              type: "application/json"
  end
end
