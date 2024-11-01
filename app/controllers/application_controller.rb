class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :doorkeeper_authorize!
  allow_browser versions: :modern

  def current_user
    @current_user ||= User.find_by(id: doorkeeper_token[:resource_owner_id])
  end

  def admin?
    current_user.role == "admin"
  end
end
