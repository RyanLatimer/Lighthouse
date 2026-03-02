require "test_helper"

class ExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @event = events(:championship)
    sign_in_as(@user)
    select_event(@event)
  end

  # --- CSV ---

  test "admin should get csv export" do
    get exports_csv_path
    assert_response :success
    assert_equal "text/csv", response.content_type.split(";").first
  end

  test "lead should get csv export" do
    sign_out :user
    sign_in_as(users(:lead_user))
    select_event(@event)

    get exports_csv_path
    assert_response :success
    assert_equal "text/csv", response.content_type.split(";").first
  end

  test "scout cannot get csv export" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get exports_csv_path
    assert_response :redirect
  end

  test "csv contains header row" do
    get exports_csv_path
    assert_response :success
    assert_includes response.body, "ID,Match,Team,Scout,Status,TotalPoints,FuelAccuracy,Notes,CreatedAt"
  end

  # --- JSON ---

  test "admin should get json export" do
    get exports_json_path
    assert_response :success
    assert_equal "application/json", response.content_type.split(";").first
  end

  test "lead should get json export" do
    sign_out :user
    sign_in_as(users(:lead_user))
    select_event(@event)

    get exports_json_path
    assert_response :success
  end

  test "scout cannot get json export" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get exports_json_path
    assert_response :redirect
  end

  test "json export contains expected structure" do
    get exports_json_path
    assert_response :success

    data = JSON.parse(response.body)
    assert data.key?("event")
    assert data.key?("team_summaries")
    assert data.key?("scouting_entries")
    assert data.key?("pit_scouting")
    assert_equal @event.name, data["event"]["name"]
  end

  # --- Excel ---

  test "admin should get excel export" do
    get exports_excel_path
    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                 response.content_type.split(";").first
  end

  test "scout cannot get excel export" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get exports_excel_path
    assert_response :redirect
  end

  # --- PDF ---

  test "admin should get pdf export" do
    get exports_pdf_path
    assert_response :success
    assert_equal "application/pdf", response.content_type.split(";").first
  end

  test "scout cannot get pdf export" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get exports_pdf_path
    assert_response :redirect
  end

  # --- Require event ---

  test "csv requires event" do
    reset!
    sign_in_as(@user)

    get exports_csv_path
    assert_redirected_to events_path
  end

  test "json requires event" do
    reset!
    sign_in_as(@user)

    get exports_json_path
    assert_redirected_to events_path
  end

  # --- Authentication ---

  test "unauthenticated user is redirected" do
    sign_out :user

    get exports_csv_path
    assert_redirected_to new_user_session_path
  end
end
