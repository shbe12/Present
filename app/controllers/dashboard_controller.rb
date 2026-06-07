class DashboardController < ApplicationController
  def index
    @members_count    = Member.count
    @active_count     = Member.active.count
    @treasury_balance = Payment.sum(:amount) - Expense.sum(:amount)
    @total_charged    = Charge.sum(:amount)
    @total_paid       = Payment.sum(:amount)
    @outstanding      = @total_charged - @total_paid

    @recent_attendances = Attendance.includes(:member).order(date: :desc).limit(5)
    @recent_payments    = Payment.includes(:member).recent.limit(5)
    @recent_expenses    = Expense.recent.limit(5)
  end
end
