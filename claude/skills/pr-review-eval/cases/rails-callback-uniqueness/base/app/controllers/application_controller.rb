class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def current_user
    @current_user ||= User.find_by(api_token: request.headers["Authorization"].to_s.delete_prefix("Bearer "))
  end

  def authenticate_user!
    head :unauthorized unless current_user
  end
end
