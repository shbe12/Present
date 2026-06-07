require "test_helper"

class AdminNavigationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "admin@example.com", password: "password123")
    @member = Member.create!(name: "Jordan")
  end

  test "unauthenticated visitor is redirected to sign in" do
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "authenticated admin can load every primary page" do
    sign_in @user

    [
      root_path,
      members_path, new_member_path, member_path(@member), edit_member_path(@member),
      attendances_path, new_attendance_path,
      charges_path, new_charge_path,
      payments_path, new_payment_path,
      expenses_path, new_expense_path,
      attendance_report_path, balances_report_path, treasury_report_path
    ].each do |path|
      get path
      assert_response :success, "expected 200 for #{path}, got #{response.status}"
    end
  end

  test "creating a late attendance through the controller generates a charge" do
    sign_in @user

    assert_difference -> { Charge.count }, 1 do
      post attendances_path, params: { attendance: { member_id: @member.id, date: Date.current, status: "late" } }
    end
    assert_redirected_to attendances_path
    assert_equal "late_fee", @member.charges.first.charge_type
  end

  test "recording a payment reduces the member balance" do
    sign_in @user
    Charge.create!(member: @member, charge_type: "uniform", amount: 30)

    post payments_path, params: { payment: { member_id: @member.id, amount: 20, paid_on: Date.current, payment_method: "cash" } }

    assert_redirected_to payments_path
    assert_equal 10, @member.reload.balance_due
  end
end
