class MembersController < ApplicationController
  before_action :set_member, only: %i[show edit update destroy invite]

  def index
    @members = Member.includes(:charges, :payments).order(:name)
  end

  def show
    @charges  = @member.charges.recent
    @payments = @member.payments.recent
  end

  def new
    @member = Member.new
  end

  def edit
  end

  def create
    @member = Member.new(member_params)
    if @member.save
      @member.send_reset_password_instructions if @member.email.present?
      redirect_to @member, notice: "Member created#{ ". Invite sent to #{@member.email}" if @member.email.present? }."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @member.update(member_params)
      redirect_to @member, notice: "Member was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @member.destroy
    redirect_to members_path, notice: "Member was successfully deleted.", status: :see_other
  end

  def invite
    @member.send_reset_password_instructions
    redirect_to @member, notice: "Invite sent to #{@member.email}."
  end

  private

  def set_member
    @member = Member.find(params[:id])
  end

  def member_params
    params.require(:member).permit(:name, :phone, :email, :active, :joined_on)
  end
end
