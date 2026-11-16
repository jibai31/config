class Tasting < ApplicationRecord
  belongs_to :user
  belongs_to :card

  validates :tasted_on, presence: true
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true

  scope :most_recent_first, -> { order(tasted_on: :desc, created_at: :desc) }
  scope :for_card, ->(card_id) { card_id.present? ? where(card_id: card_id) : all }
end
