class AttendancesController < ApplicationController
  before_action :set_attendance, only: %i[show edit update destroy]

  def index
    @attendances = Attendance.includes(:member).order(date: :desc)
  end

  def show
  end

  def bulk_new
    @date = params[:date].presence || Date.current
    @members = Member.active.order(:name)
    @existing = Attendance.where(date: @date, member: @members).pluck(:member_id)
  end

  def bulk_create
    date = params[:date].presence || Date.current
    created, skipped = save_bulk_attendances(date, params[:members] || {})

    flash[:alert] = "Skipped — #{skipped.join('; ')}" if skipped.any?
    redirect_to attendances_path, notice: "#{created} attendance record(s) saved."
  end

  def new
    @attendance = Attendance.new(date: Date.current)
  end

  def edit
  end

  def create
    @attendance = Attendance.new(attendance_params)
    if @attendance.save
      redirect_to attendances_path, notice: "Attendance was successfully recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @attendance.update(attendance_params)
      redirect_to attendances_path, notice: "Attendance was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @attendance.destroy
    redirect_to attendances_path, notice: "Attendance was successfully deleted.", status: :see_other
  end

  private

  def set_attendance
    @attendance = Attendance.find(params[:id])
  end

  def attendance_params
    params.require(:attendance).permit(:member_id, :date, :status, :notes)
  end

  def save_bulk_attendances(date, member_attrs)
    created = 0
    skipped = []

    member_attrs.each do |member_id, attrs|
      next if attrs[:status].blank?

      attendance = build_attendance(member_id, date, attrs)
      attendance.save ? created += 1 : skipped << attendance_error(member_id, attendance)
    end

    [created, skipped]
  end

  def build_attendance(member_id, date, attrs)
    Attendance.new(member_id: member_id, date: date, status: attrs[:status], notes: attrs[:notes].presence)
  end

  def attendance_error(member_id, attendance)
    "#{Member.find(member_id).name}: #{attendance.errors.full_messages.join(', ')}"
  end
end
