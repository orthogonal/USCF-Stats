class DeltasController < ApplicationController
  require 'UscfWebsite'
  def index
    render(:action => "index")
  end
  
  def buildchart
    history = UscfWebsite.get_rating_history_from_id(params[:uscf_id], 0)
    @data = Array.new
    history.each do |event|
      result = UscfWebsite.get_results_against_opponents_from_tournament(params[:uscf_id], event[:id], event[:section])
      result.each do |row|
        rating = (event[:regular][:pre] != 0) ? event[:regular][:pre] : event[:regular][:post]
        @data << {:wdl => row[:wdl], :rating => rating, :delta => (row[:regular].to_i - rating), :name => (row[:name])}
      end
    end
    respond_to do |format|
      format.js {}
    end
  end
end
