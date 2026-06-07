class Member < ApplicationRecord
  include RefreshesDashboard

  has_many :attendances, dependent: :destroy
  has_many :charges, dependent: :destroy
  has_many :payments, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(active: true) }

  # Computed on demand. Use `includes(:charges, :payments)` when listing many
  # members so the block-form sums run in Ruby against eager-loaded records
  # instead of firing a query per member.
  def balance_due
    charges.sum(&:amount) - payments.sum(&:amount)
  end

  def amount_owed
    [balance_due, 0].max
  end

  def to_s
    name
  end
end
