require "application_system_test_case"

class PaymentsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email: "admin@example.com", password: "password123")
    @member = Member.create!(name: "Jordan")
    Charge.create!(member: @member, charge_type: "uniform", amount: 30)
    sign_in_as(@user)
  end

  test "admin records a payment which reduces the member balance" do
    visit member_path(@member)
    assert_text "$30.00" # balance due before payment

    click_on "Record payment"
    fill_in "Amount", with: "20"
    fill_in "Paid on", with: Date.current
    select "Cash", from: "Payment method"
    click_on "Create Payment"

    assert_text "Payment was successfully recorded."

    visit member_path(@member)
    assert_text "$10.00" # remaining balance
  end
end
