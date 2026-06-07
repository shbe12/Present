# Re-renders the dashboard stat cards on every open dashboard whenever a record
# that feeds those aggregates changes. The partial recomputes the figures, so
# create/update/destroy all funnel through one broadcast.
module RefreshesDashboard
  extend ActiveSupport::Concern

  included do
    after_commit :refresh_dashboard_stats
  end

  private

  def refresh_dashboard_stats
    broadcast_replace_to "dashboard", target: "dashboard_stats", partial: "dashboard/stats"
  end
end
