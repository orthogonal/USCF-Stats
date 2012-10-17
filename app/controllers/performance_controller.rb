class PerformanceController < ApplicationController
  require "UscfWebsite"
  require "UscfMath"
  
  def index
    render :action => "index"
  end
  
  def tournament_history
    if !(params[:uscf_id].match(/\d{8}/))
      render :js => ""
      return
    end
    session[:type] = (params[:type] == "regular") ? UscfWebsite::REGULAR : UscfWebsite::QUICK
    history = UscfWebsite.get_rating_history_from_id(params[:uscf_id], session[:type])
    result = Array.new;
    for i in 0...history.length do
      result << {:id => history[i][:id], :section => history[i][:section], :name => history[i][:name], :date => history[i][:date],
        :rating => (session[:type] == UscfWebsite::REGULAR ? (history[i][:regular][:pre] != 0) ? history[i][:regular][:pre] : history[i][:regular][:post]
                                                 : (history[i][:quick][:pre] != 0) ? history[i][:quick][:pre] : history[i][:quick][:post])}
    end
    render :js => result.to_json
  end
  
  def performance_result
    tourn_result = UscfWebsite.get_results_against_opponents_from_tournament(params[:uscf_id], params[:tournament], params[:section])
    results = Array.new
    tourn_result.each do |row|
      results << {:wdl => row[:wdl], :opp => (session[:type] == UscfWebsite::REGULAR ? row[:regular].to_i : row[:quick].to_i)}
    end
    performances = {:name => params[:name], :date => params[:date], :performance => UscfMath.performance(results), :rating => params[:rating]}
    render :js => performances.to_json
  end
  
  def build_chart
    @performances = params[:results].to_hash.map{|key, value| value}
    @performances.map!{|record| record.symbolize_keys}
    respond_to do |format|
       format.js {}
     end
  end
end
