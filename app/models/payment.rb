class Payment < ApplicationRecord
  include RefreshesDashboard
  include RefreshesMemberBalance

  belongs_to :member

  enum :payment_method, {
    cash: "cash",
    etransfer: "etransfer",
    credit_card: "credit_card",
    other: "other"
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paid_on, presence: true
  validates :payment_method, presence: true

  scope :recent, -> { order(paid_on: :desc) }
end
