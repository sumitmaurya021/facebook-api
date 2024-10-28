class HomeController < ApplicationController
  skip_before_action :doorkeeper_authorize!, only: [ :index ]
  def index
    render html: "Hello World!"
  end
end
