class PerformanceController < ApplicationController
  require "UscfWebsite"
  require "UscfMath"
  
  def index
    history = UscfWebsite.get_rating_history_from_id(13434851, UscfWebsite::REGULAR)
    tournaments = Array.new
    @performances = Array.new
    for i in 0...history.length do
      tournaments << {:id => history[i][:id], :section => history[i][:section], 
        :rating => (history[i][:regular][:pre] != 0) ? history[i][:regular][:pre] : history[i][:regular][:post]}
    end
    history.each do |event|
      tourn_result = UscfWebsite.get_results_against_opponents_from_tournament(13434851, event[:id], event[:section])
      results = Array.new
      tourn_result.each do |row|
        results << {:wdl => row[:wdl], :opp => row[:regular].to_i}
      end
      @performances << {:date => event[:date], :performance => UscfMath.performance(results), 
        :rating => (event[:regular][:pre] != 0) ? event[:regular][:pre] : event[:regular][:post]}
    end
    render :action => "index"
  end
end
