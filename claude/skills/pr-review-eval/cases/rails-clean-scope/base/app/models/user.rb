class User < ApplicationRecord
  has_many :tastings, dependent: :destroy
  has_secure_token :api_token
end
