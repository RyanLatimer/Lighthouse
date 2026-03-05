require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @event = events(:championship)
    @report = reports(:team_summary_report)
    sign_in_as(@user)
    select_event(@event)
  end

  # --- Index ---

  test "should get index" do
    get reports_path
    assert_response :success
  end

  test "lead can get index" do
    sign_out :user
    sign_in_as(users(:lead_user))
    select_event(@event)

    get reports_path
    assert_response :success
  end

  test "scout sees scoped index via policy_scope" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    # policy_scope filters to user's own reports; doesn't deny access
    get reports_path
    assert_response :success
  end

  test "index requires event" do
    reset!
    sign_in_as(@user)

    get reports_path
    assert_redirected_to events_path
  end

  # --- Show ---

  test "should get show" do
    get report_path(@report)
    assert_response :success
  end

  test "lead can get show" do
    sign_out :user
    sign_in_as(users(:lead_user))
    select_event(@event)

    get report_path(@report)
    assert_response :success
  end

  test "scout cannot get show" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get report_path(@report)
    # Pundit denies via authorize — redirects
    assert_response :redirect
  end

  # --- New ---

  test "admin should get new" do
    get new_report_path
    assert_response :success
  end

  test "scout cannot get new" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get new_report_path
    assert_response :redirect
  end

  # --- Create ---

  test "admin should create report" do
    assert_difference("Report.count", 1) do
      post reports_path, params: {
        report: {
          name: "Test Report",
          config: { metrics: [ "avg_total_points" ], sort_by: "avg_total_points" }
        }
      }
    end
    assert_redirected_to report_path(Report.last)
  end

  test "scout cannot create report" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    assert_no_difference("Report.count") do
      post reports_path, params: {
        report: {
          name: "Scout Report",
          config: {}
        }
      }
    end
    assert_response :redirect
  end

  test "create with missing name renders new" do
    assert_no_difference("Report.count") do
      post reports_path, params: {
        report: {
          name: "",
          config: {}
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # --- Authentication ---

  test "unauthenticated user is redirected" do
    sign_out :user

    get reports_path
    assert_redirected_to new_user_session_path
  end
end
