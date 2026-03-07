require "test_helper"

class ScoutingAssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:championship)
    sign_in_as(users(:admin_user))
    select_event(@event)
  end

  # --- Index ---

  test "admin can view schedule" do
    get scouting_assignments_path
    assert_response :success
    assert_match "Scouting Schedule", response.body
  end

  test "scout sees own assignments only" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get scouting_assignments_path
    assert_response :success
    assert_match "My lane", response.body
    assert_no_match "Admin User", response.body
  end

  # --- Bulk Create ---

  test "admin can bulk create assignments" do
    assert_difference("ScoutingAssignment.count", 1) do
      post bulk_create_scouting_assignments_path, params: {
        user_ids: [ users(:lead_user).id ],
        start_match_number: 1,
        end_match_number: 1,
        notes: "Coverage"
      }
    end

    assert_redirected_to scouting_assignments_path
  end

  test "scout cannot bulk create assignments" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    post bulk_create_scouting_assignments_path, params: {
      user_ids: [ users(:lead_user).id ],
      start_match_number: 1,
      end_match_number: 1
    }

    assert_response :redirect
  end

  # --- Bulk Destroy ---

  test "admin can clear assignments in range" do
    assert_difference("ScoutingAssignment.count", -2) do
      post bulk_destroy_scouting_assignments_path, params: {
        user_ids: [ users(:admin_user).id ],
        start_match_number: 1,
        end_match_number: 2
      }
    end

    assert_redirected_to scouting_assignments_path
  end

  # --- Single Destroy ---

  test "admin can remove single assignment" do
    assignment = scouting_assignments(:scout_qm2)

    assert_difference("ScoutingAssignment.count", -1) do
      delete scouting_assignment_path(assignment)
    end

    assert_redirected_to scouting_assignments_path
  end

  # --- Toggle ---

  test "admin can toggle on an assignment" do
    match = matches(:qm1)
    user = users(:lead_user)

    assert_difference("ScoutingAssignment.count", 1) do
      post toggle_scouting_assignments_path,
           params: { user_id: user.id, match_id: match.id },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
  end

  test "admin can toggle off an existing assignment" do
    assignment = scouting_assignments(:scout_qm2)

    assert_difference("ScoutingAssignment.count", -1) do
      post toggle_scouting_assignments_path,
           params: { user_id: assignment.user_id, match_id: assignment.match_id },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
  end

  test "toggle responds with turbo stream" do
    match = matches(:qm1)
    user = users(:lead_user)

    post toggle_scouting_assignments_path,
         params: { user_id: user.id, match_id: match.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "turbo-stream", response.body
  end

  test "scout cannot toggle assignments" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    post toggle_scouting_assignments_path, params: {
      user_id: users(:scout_user).id,
      match_id: matches(:qm1).id
    }

    assert_response :redirect
  end
end
