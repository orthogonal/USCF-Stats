class PerformanceController < ApplicationController
  require "UscfWebsite"
  require "UscfMath"
  
  def index
    render :action => "index"
  end
  
  def build_chart
    history = UscfWebsite.get_rating_history_from_id(params[:uscf_id], UscfWebsite::REGULAR)
    tournaments = Array.new
    @performances = Array.new
    for i in 0...history.length do
      tournaments << {:id => history[i][:id], :section => history[i][:section], 
        :rating => (history[i][:regular][:pre] != 0) ? history[i][:regular][:pre] : history[i][:regular][:post]}
    end
    history.each do |event|
      tourn_result = UscfWebsite.get_results_against_opponents_from_tournament(params[:uscf_id], event[:id], event[:section])
      results = Array.new
      tourn_result.each do |row|
        results << {:wdl => row[:wdl], :opp => row[:regular].to_i}
      end
      @performances << {:name => event[:name], :date => event[:date], :performance => UscfMath.performance(results), 
        :rating => (event[:regular][:pre] != 0) ? event[:regular][:pre] : event[:regular][:post]}
    end
    respond_to do |format|
       format.js {}
     end
  end
end
