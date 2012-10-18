class WpwController < ApplicationController
  require 'UscfWebsite'
  def index
    @results = UscfWebsite.all_games_in_tournament(201001232121, 1, 0)
    render :action => "index"
  end
end
