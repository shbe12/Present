class Expense < ApplicationRecord
  include RefreshesDashboard

  enum :category, {
    uniforms: "uniforms",
    activities: "activities",
    equipment: "equipment",
    food: "food",
    transportation: "transportation",
    facility_rental: "facility_rental",
    other: "other"
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :category, presence: true
  validates :spent_on, presence: true

  scope :recent, -> { order(spent_on: :desc) }
end
