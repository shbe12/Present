class ReportsController < ApplicationController
  # Per-event attendance log, most recent first.
  def attendance
    @attendances = Attendance.includes(:member).order(date: :desc)
    @counts_by_status = Attendance.group(:status).count
  end

  # Per-member balance (charges minus payments).
  def balances
    @members = Member.includes(:charges, :payments).order(:name)
  end

  # Group treasury: payments received minus expenses paid out.
  def treasury
    @total_income   = Payment.sum(:amount)
    @total_expenses = Expense.sum(:amount)
    @treasury_balance = @total_income - @total_expenses
    @income_by_method = Payment.group(:payment_method).sum(:amount)
    @expenses_by_category = Expense.group(:category).sum(:amount)
  end
end
