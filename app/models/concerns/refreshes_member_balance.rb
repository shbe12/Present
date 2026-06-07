# Replaces the member's balance figure wherever it is shown (members index,
# member page, balances report) whenever a charge or payment commits. The
# balance lives in a single `members/_balance` partial keyed by dom id, so one
# broadcast updates every occurrence.
module RefreshesMemberBalance
  extend ActiveSupport::Concern

  included do
    after_commit :refresh_member_balance
  end

  private

  def refresh_member_balance
    return unless member
    # return if Rails.env.test? //guard broadcasts for testing.//

    broadcast_replace_to "members",
      target: ActionView::RecordIdentifier.dom_id(member, :balance),
      partial: "members/balance",
      locals: { member: member }
  end
end
