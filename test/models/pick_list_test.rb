require "test_helper"

class PickListTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid pick list from fixtures" do
    assert pick_lists(:championship_picks).valid?
  end

  test "requires name" do
    pick_list = pick_lists(:championship_picks)
    pick_list.name = nil
    assert_not pick_list.valid?
    assert_includes pick_list.errors[:name], "can't be blank"
  end

  # --- Associations ---

  test "belongs to event" do
    assert_equal events(:championship), pick_lists(:championship_picks).event
  end

  test "belongs to user" do
    assert_equal users(:admin_user), pick_lists(:championship_picks).user
  end

  # --- Fixture data ---

  test "championship_picks has correct name" do
    assert_equal "Championship Pick List", pick_lists(:championship_picks).name
  end

  test "championship_picks entries contain team data" do
    pick_list = PickList.create!(
      name: "Test Picks",
      entries: [
        { "rank" => 1, "team_number" => 254, "notes" => "Top pick" },
        { "rank" => 2, "team_number" => 1678, "notes" => "Strong second" }
      ],
      event: events(:championship),
      user: users(:admin_user)
    )
    entries = pick_list.reload.entries
    assert_kind_of Array, entries
    assert_equal 2, entries.length
    assert_equal 1, entries.first["rank"]
    assert_equal 254, entries.first["team_number"]
  end
end
