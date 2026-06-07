class PaymentsController < ApplicationController
  before_action :set_payment, only: %i[show edit update destroy]

  def index
    @payments = Payment.includes(:member).recent
  end

  def show
  end

  def new
    @payment = Payment.new(paid_on: Date.current, payment_method: :cash, member_id: params.dig(:payment, :member_id))
  end

  def edit
  end

  def create
    @payment = Payment.new(payment_params)
    if @payment.save
      redirect_to payments_path, notice: "Payment was successfully recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @payment.update(payment_params)
      redirect_to payments_path, notice: "Payment was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @payment.destroy
    redirect_to payments_path, notice: "Payment was successfully deleted.", status: :see_other
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:member_id, :amount, :paid_on, :payment_method, :notes)
  end
end
