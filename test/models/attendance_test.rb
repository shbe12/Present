require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  setup do
    @member = Member.create!(name: "Alex")
  end

  test "late attendance creates a late_fee charge" do
    attendance = Attendance.create!(member: @member, date: Date.current, status: "late")

    charge = attendance.charge
    assert_not_nil charge
    assert_equal "late_fee", charge.charge_type
    assert_equal Attendance::LATE_FEE, charge.amount
    assert_equal @member, charge.member
  end

  test "no_show attendance creates a no_show_fee charge" do
    attendance = Attendance.create!(member: @member, date: Date.current, status: "no_show")

    assert_equal "no_show_fee", attendance.charge.charge_type
    assert_equal Attendance::NO_SHOW_FEE, attendance.charge.amount
  end

  test "present and excused attendance create no charge" do
    present = Attendance.create!(member: @member, date: Date.current, status: "present")
    excused = Attendance.create!(member: @member, date: Date.current + 1.day, status: "excused")

    assert_nil present.charge
    assert_nil excused.charge
    assert_equal 0, @member.charges.count
  end

  test "re-saving an unchanged attendance does not double-charge" do
    attendance = Attendance.create!(member: @member, date: Date.current, status: "late")
    attendance.update!(notes: "arrived 10 minutes late")

    assert_equal 1, @member.charges.count
  end

  test "correcting status from late to present voids the charge" do
    attendance = Attendance.create!(member: @member, date: Date.current, status: "late")
    assert_equal 1, @member.charges.count

    attendance.update!(status: "present")

    assert_equal 0, @member.reload.charges.count
    assert_nil attendance.reload.charge
  end

  test "correcting status from late to no_show replaces the charge" do
    attendance = Attendance.create!(member: @member, date: Date.current, status: "late")
    attendance.update!(status: "no_show")

    assert_equal 1, @member.reload.charges.count
    assert_equal "no_show_fee", attendance.reload.charge.charge_type
    assert_equal Attendance::NO_SHOW_FEE, attendance.charge.amount
  end

  test "cannot create duplicate attendance for same member and date" do
    Attendance.create!(
      member: @member,
      date: Date.current,
      status: "present"
    )

    duplicate = Attendance.new(
      member: @member,
      date: Date.current,
      status: "late"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:date], "already has an attendance record"
  end

  test "updating an existing attendance does not trigger uniqueness validation" do
    attendance = Attendance.create!(
      member: @member,
      date: Date.current,
      status: "late"
    )

    assert attendance.update(status: "no_show")

    assert_equal "no_show", attendance.reload.status
    assert_equal 1, Charge.where(attendance: attendance).count
  end

  test "destroying an attendance removes its automatic charge" do
    attendance = Attendance.create!(member: @member, date: Date.current, status: "late")
    assert_difference -> { Charge.count }, -1 do
      attendance.destroy!
    end
  end

  test "automatic charge does not disturb manual charges on status change" do
    Charge.create!(member: @member, charge_type: "uniform", amount: 20)
    attendance = Attendance.create!(member: @member, date: Date.current, status: "late")
    attendance.update!(status: "present")

    assert_equal 1, @member.reload.charges.count
    assert_equal "uniform", @member.charges.first.charge_type
  end
end
