class WpwController < ApplicationController
  require 'UscfWebsite'
  def index
    render :action => "index"
  end
  
  def build_graph
    @results = UscfWebsite.all_games_in_tournament(params[:id], params[:section], 0)
    respond_to do |format|
      format.js {}
    end
  end
end
