require "test_helper"

class MemberTest < ActiveSupport::TestCase
  test "requires a name" do
    assert_not Member.new.valid?
    assert Member.new(name: "Sam").valid?
  end

  test "balance_due is zero with no charges or payments" do
    member = Member.create!(name: "Sam")
    assert_equal 0, member.balance_due
  end

  test "balance_due is charges minus payments" do
    member = Member.create!(name: "Sam")
    Charge.create!(member: member, charge_type: "uniform", amount: 30)
    Charge.create!(member: member, charge_type: "activity", amount: 10)
    Payment.create!(member: member, amount: 25, paid_on: Date.current, payment_method: "cash")

    assert_equal 15, member.balance_due
  end

  test "balance_due can be negative when overpaid" do
    member = Member.create!(name: "Sam")
    Charge.create!(member: member, charge_type: "other", amount: 5)
    Payment.create!(member: member, amount: 20, paid_on: Date.current, payment_method: "cash")

    assert_equal(-15, member.balance_due)
  end

  test "active scope returns only active members" do
    active = Member.create!(name: "Active")
    Member.create!(name: "Inactive", active: false)

    assert_equal [ active ], Member.active.to_a
  end
end
