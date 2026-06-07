class ChargesController < ApplicationController
  before_action :set_charge, only: %i[show edit update destroy]

  def index
    @charges = Charge.includes(:member).recent
  end

  def show
  end

  def new
    @charge = Charge.new(charge_type: :other, member_id: params.dig(:charge, :member_id))
  end

  def edit
  end

  def create
    @charge = Charge.new(charge_params)
    if @charge.save
      redirect_to charges_path, notice: "Charge was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @charge.update(charge_params)
      redirect_to charges_path, notice: "Charge was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @charge.destroy
    redirect_to charges_path, notice: "Charge was successfully deleted.", status: :see_other
  end

  private

  def set_charge
    @charge = Charge.find(params[:id])
  end

  def charge_params
    params.require(:charge).permit(:member_id, :amount, :charge_type, :description, :due_date)
  end
end
