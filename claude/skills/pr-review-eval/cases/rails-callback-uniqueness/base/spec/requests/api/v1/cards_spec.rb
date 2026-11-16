require "rails_helper"

RSpec.describe "Cards API" do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.api_token}" } }

  it "lists cards by name" do
    create(:card, name: "Comté")
    create(:card, name: "Beaufort")

    get "/api/v1/cards", headers: headers

    expect(response.parsed_body.pluck("name")).to eq(%w[Beaufort Comté])
  end

  it "rejects anonymous requests" do
    get "/api/v1/cards"

    expect(response).to have_http_status(:unauthorized)
  end
end
