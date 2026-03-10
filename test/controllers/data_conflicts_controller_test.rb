require "test_helper"

class DataConflictsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @event = events(:championship)
    @conflict = data_conflicts(:conflict_qm1_254_climb)
    sign_in_as(@user)
    select_event(@event)
  end

  test "admin can resolve a conflict" do
    post resolve_data_conflict_path(@conflict), params: { resolution: "high" }

    assert_redirected_to data_conflicts_path

    @conflict.reload
    assert @conflict.resolved
    assert_equal @user, @conflict.resolved_by
    assert_equal "high", @conflict.resolution_value
  end

  test "scout cannot resolve a conflict" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    post resolve_data_conflict_path(@conflict), params: { resolution: "high" }

    assert_response :redirect

    @conflict.reload
    assert_not @conflict.resolved
    assert_nil @conflict.resolved_by
    assert_nil @conflict.resolution_value
  end
end
