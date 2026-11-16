require "rails_helper"

RSpec.describe Tasting do
  describe ".most_recent_first" do
    it "orders by tasting date, then creation time" do
      older = create(:tasting, tasted_on: Date.new(2026, 1, 1))
      newer = create(:tasting, tasted_on: Date.new(2026, 2, 1))
      same_day_later = create(:tasting, tasted_on: Date.new(2026, 2, 1), created_at: 1.minute.from_now)

      expect(described_class.most_recent_first).to eq([same_day_later, newer, older])
    end
  end

  describe ".for_card" do
    it "filters by card when given" do
      tasting = create(:tasting)
      create(:tasting)

      expect(described_class.for_card(tasting.card_id)).to eq([tasting])
    end

    it "returns everything when the card is blank" do
      create_list(:tasting, 2)

      expect(described_class.for_card(nil).count).to eq(2)
    end
  end
end
