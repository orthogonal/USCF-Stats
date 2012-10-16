class PerformanceController < ApplicationController
  require "UscfWebsite"
  require "UscfMath"
  
  def index
    render :action => "index"
  end
  
  def build_chart
    type = (params[:type] == "regular") ? UscfWebsite::REGULAR : UscfWebsite::QUICK
    history = UscfWebsite.get_rating_history_from_id(params[:uscf_id], type)
    tournaments = Array.new
    @performances = Array.new
    for i in 0...history.length do
      tournaments << {:id => history[i][:id], :section => history[i][:section], 
        :rating => (type == UscfWebsite::REGULAR ? (history[i][:regular][:pre] != 0) ? history[i][:regular][:pre] : history[i][:regular][:post]
                                                 : (history[i][:quick][:pre] != 0) ? history[i][:quick][:pre] : history[i][:quick][:post])}
        end
    history.each do |event|
      tourn_result = UscfWebsite.get_results_against_opponents_from_tournament(params[:uscf_id], event[:id], event[:section])
      results = Array.new
      tourn_result.each do |row|
        results << {:wdl => row[:wdl], :opp => (type == UscfWebsite::REGULAR ? row[:regular].to_i : row[:quick].to_i)}
      end
      @performances << {:name => event[:name], :date => event[:date], :performance => UscfMath.performance(results), 
        :rating => (type == UscfWebsite::REGULAR ? (event[:regular][:pre] != 0) ? event[:regular][:pre] : event[:regular][:post]
                                                 : (event[:quick][:pre] != 0) ? event[:quick][:pre] : event[:quick][:post])}
        end
    respond_to do |format|
       format.js {}
     end
  end
end
