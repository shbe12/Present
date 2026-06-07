module ApplicationHelper
  # Consistent currency formatting across views.
  def money(amount)
    number_to_currency(amount || 0)
  end

  # Bootstrap badge for an attendance status.
  def attendance_status_badge(status)
    klass = {
      "present" => "text-bg-success",
      "late" => "text-bg-warning",
      "no_show" => "text-bg-danger",
      "excused" => "text-bg-secondary"
    }.fetch(status, "text-bg-secondary")
    tag.span(status.humanize, class: "badge #{klass}")
  end
end
