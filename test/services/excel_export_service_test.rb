# frozen_string_literal: true

require "test_helper"

class ExcelExportServiceTest < ActiveSupport::TestCase
  setup do
    @event = events(:championship)
    @service = ExcelExportService.new(@event)
  end

  test "generate returns non-nil content" do
    content = @service.generate
    assert_not_nil content, "Excel export should return content"
  end

  test "generate returns non-empty binary string" do
    content = @service.generate
    assert content.is_a?(String), "Expected a string"
    assert content.length > 0, "Excel content should not be empty"
  end

  test "generate returns valid xlsx data" do
    content = @service.generate

    # XLSX files are ZIP archives; they start with the ZIP magic bytes "PK"
    assert_equal "PK", content[0..1], "XLSX content should start with PK (ZIP magic bytes)"
  end

  test "generate includes all three worksheets" do
    content = @service.generate

    # XLSX files are ZIP archives containing XML. Sheet names are stored in
    # xl/workbook.xml. We can extract and verify by reading the ZIP entries.
    require "zip"
    io = StringIO.new(content)
    workbook_xml = nil

    Zip::InputStream.open(io) do |zip|
      while (entry = zip.get_next_entry)
        if entry.name == "xl/workbook.xml"
          workbook_xml = zip.read
          break
        end
      end
    end

    assert_not_nil workbook_xml, "XLSX should contain xl/workbook.xml"
    assert workbook_xml.include?("Team Summary"), "Should contain Team Summary sheet"
    assert workbook_xml.include?("Raw Scouting Data"), "Should contain Raw Scouting Data sheet"
    assert workbook_xml.include?("Pit Scouting"), "Should contain Pit Scouting sheet"
  end

  test "generate works with event that has scouting entries" do
    # Championship has 4 scouting entries across 2 teams
    assert @event.scouting_entries.count >= 4,
           "Fixture event should have scouting entries"

    content = @service.generate
    assert content.length > 100, "XLSX with data should be substantial"
  end

  test "generate works with event that has no scouting entries" do
    # Create an event with no data
    empty_event = Event.create!(
      name: "Empty Event",
      tba_key: "2026empty",
      start_date: "2026-05-01",
      end_date: "2026-05-03",
      city: "Nowhere",
      state_prov: "XX",
      country: "USA",
      event_type: 0,
      year: 2026,
      week: 1
    )

    service = ExcelExportService.new(empty_event)
    content = service.generate

    assert_not_nil content
    assert content.length > 0, "Should still produce a valid XLSX with headers"
  end
end
