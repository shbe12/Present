class AttendancesController < ApplicationController
  before_action :set_attendance, only: %i[show edit update destroy]

  def index
    @attendances = Attendance.includes(:member).order(date: :desc)
  end

  def show
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
end
