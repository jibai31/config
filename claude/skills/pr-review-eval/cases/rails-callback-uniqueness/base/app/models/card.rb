class Card < ApplicationRecord
  has_many :tastings, dependent: :restrict_with_error

  validates :name, presence: true
end
