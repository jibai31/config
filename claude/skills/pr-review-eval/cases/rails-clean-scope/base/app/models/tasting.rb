class Tasting < ApplicationRecord
  belongs_to :user
  belongs_to :card

  validates :tasted_on, presence: true
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true
end
