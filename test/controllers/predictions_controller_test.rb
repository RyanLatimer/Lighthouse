require "test_helper"

class PredictionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @event = events(:championship)
    @prediction = predictions(:prediction_qm1)
    @match = matches(:qm1)
    sign_in_as(@user)
    select_event(@event)
  end

  # --- Index ---

  test "should get index" do
    get predictions_path
    assert_response :success
  end

  test "scout cannot get index" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get predictions_path
    assert_response :redirect
  end

  test "index requires event" do
    reset!
    sign_in_as(@user)

    get predictions_path
    assert_redirected_to events_path
  end

  # --- Show ---

  test "should get show" do
    get prediction_path(@match)
    assert_response :success
  end

  test "scout cannot get show" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get prediction_path(@match)
    assert_response :redirect
  end

  # --- Generate ---

  test "admin can generate predictions" do
    post generate_predictions_path
    # Either redirects on success or failure
    assert_response :redirect
    assert_redirected_to predictions_path
  end

  test "scout cannot generate predictions" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    post generate_predictions_path
    # Pundit redirects back
    assert_response :redirect
  end

  # --- Authentication ---

  test "unauthenticated user is redirected" do
    sign_out :user

    get predictions_path
    assert_redirected_to new_user_session_path
  end
end
