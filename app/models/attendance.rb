class Attendance < ApplicationRecord
  # Automatic fee amounts (dollars). Business rule — not runtime-configurable for MVP.
  LATE_FEE    = 5
  NO_SHOW_FEE = 10

  belongs_to :member
  # The charge automatically generated from this attendance. Manual charges have
  # no attendance and are unaffected by the callbacks below.
  has_one :charge, dependent: :destroy

  enum :status, {
    present: "present",
    late: "late",
    no_show: "no_show",
    excused: "excused"
  }

  validates :date, presence: true
  validates :status, presence: true

  validates :date, uniqueness: { scope: :member_id, message: "already has an attendance record" }

  after_create :create_automatic_charge
  after_update :resync_automatic_charge, if: :saved_change_to_status?

  # Keep the attendance index live across every open page. The auto charge it
  # may create broadcasts its own balance/dashboard updates separately.
  after_create_commit  -> { broadcast_prepend_to "attendances" }
  after_update_commit  -> { broadcast_replace_to "attendances" }
  after_destroy_commit -> { broadcast_remove_to "attendances" }

  private

  # Fires once on create. Re-saving an unchanged record never re-enters here,
  # so there is no double-charging.
  def create_automatic_charge
    type, amount = automatic_charge_for_status
    return if type.nil?

    Charge.create!(
      member: member,
      attendance: self,
      charge_type: type,
      amount: amount,
      description: "#{status.humanize} attendance on #{date}",
      due_date: date
    )
  end

  # Status corrected after the fact: drop the stale auto charge and recreate the
  # correct one (or none). Manual charges are never touched.
  def resync_automatic_charge
    charge&.destroy!
    reload_charge
    create_automatic_charge
  end

  def automatic_charge_for_status
    case status
    when "late"    then [:late_fee, LATE_FEE]
    when "no_show" then [:no_show_fee, NO_SHOW_FEE]
    end
  end
end
