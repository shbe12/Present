class Member < ApplicationRecord
  include RefreshesDashboard

  devise :database_authenticatable, :recoverable, :rememberable

  has_many :attendances, dependent: :destroy
  has_many :charges, dependent: :destroy
  has_many :payments, dependent: :destroy

  validates :name, presence: true
  validates :email, uniqueness: true, allow_blank: true

  scope :active, -> { where(active: true) }

  def balance_due
    charges.sum(:amount) - payments.sum(:amount)
  end

  def amount_owed
    [balance_due, 0].max
  end

  def to_s
    name
  end
end
