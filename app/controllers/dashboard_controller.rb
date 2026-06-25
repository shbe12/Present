class DashboardController < ApplicationController
  def index
    set_summary_metrics
    set_recent_activity
  end

  private

  def set_summary_metrics
    @members_count    = Member.count
    @active_count     = Member.active.count
    @treasury_balance = Payment.sum(:amount) - Expense.sum(:amount)
    @total_charged    = Charge.sum(:amount)
    @total_paid       = Payment.sum(:amount)
    @outstanding      = Member.includes(:charges, :payments).sum(&:amount_owed)
    @expense          = Expense.sum(:amount)
  end

  def set_recent_activity
    @recent_attendances = Attendance.includes(:member).where(status: %w[late no_show]).order(date: :desc).limit(5)
    @recent_charges     = Charge.includes(:member).recent.limit(5)
    @recent_payments    = Payment.includes(:member).recent.limit(5)
    @recent_expenses    = Expense.recent.limit(5)
  end
end
