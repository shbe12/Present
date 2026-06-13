class Portal::DashboardController < ApplicationController
  layout "portal"
  before_action :authenticate_member!

  def show
    @member = current_member.then do |m|
      Member.includes(:charges, :payments, :attendances).find(m.id)
    end
    @charges = @member.charges.order(created_at: :desc)
    @payments = @member.payments.order(paid_on: :desc)
    @attendances = @member.attendances.order(date: :desc)
  end
end
