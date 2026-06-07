require "application_system_test_case"

class AttendancesTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email: "admin@example.com", password: "password123")
    @member = Member.create!(name: "Jordan")
    sign_in_as(@user)
  end

  test "admin records a late attendance and an automatic charge appears" do
    visit attendances_path
    click_on "Record attendance"

    select "Jordan", from: "Member"
    fill_in "Date", with: Date.current
    select "Late", from: "Status"
    click_on "Create Attendance"

    assert_text "Attendance was successfully recorded."
    assert_text "Jordan"

    # The late fee should now be reflected on the member's balance.
    visit member_path(@member)
    assert_text "$5.00"
  end

  test "admin records a present attendance with no charge" do
    visit new_attendance_path
    select "Jordan", from: "Member"
    fill_in "Date", with: Date.current
    select "Present", from: "Status"
    click_on "Create Attendance"

    assert_text "Attendance was successfully recorded."
    assert_equal 0, @member.charges.count
  end
end
