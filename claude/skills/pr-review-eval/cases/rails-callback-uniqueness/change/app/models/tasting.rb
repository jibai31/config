class Tasting < ApplicationRecord
  MILESTONE_EVERY = 10

  belongs_to :user
  belongs_to :card

  validates :tasted_on, presence: true
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true
  validates :card_id, uniqueness: { scope: :user_id }

  after_save :notify_milestone

  private

  def notify_milestone
    return unless (user.tastings.count % MILESTONE_EVERY).zero?

    MilestoneMailer.with(user: user, count: user.tastings.count).reached.deliver_later
  end
end
