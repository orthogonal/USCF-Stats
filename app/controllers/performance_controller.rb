class PerformanceController < ApplicationController
  require "UscfWebsite"
  require "UscfMath"
  require "LinearRegression"
  
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
    if (tourn_result.length == 0)
      render :js => {}
      return
    end
    performances = {:name => params[:name], :date => params[:date], :performance => UscfMath.performance(results), :rating => params[:rating]}
    render :js => performances.to_json
  end
  
  def build_chart
    puts "PARAMETERS: #{params}"
    @extend = params[:extend]
    @performances = params[:results].to_hash.map{|key, value| value}
    @performances.map!{|record| record.symbolize_keys}
    mindate = @performances.min_by{|d| d[:date].to_i}[:date].to_i
    
    x = Array.new
    perf_y = Array.new
    rate_y = Array.new
    for i in 0...@performances.length
      x[i] = Array.new
      perf_y[i] = Array.new
      rate_y[i] = Array.new
      x[i][0] = Math.log(date_int(@performances[i][:date]) - date_int(mindate) + 1)
      x[i][1] = x[i][0]**2
      perf_y[i][0] = @performances[i][:performance].to_i
      rate_y[i][0] = @performances[i][:rating].to_i
    end
    
    @perfLinReg = LinearRegression.new
    @perfLinReg.training_data[:x] = x.clone
    @perfLinReg.training_data[:y] = perf_y
    @perfLinReg.normal_equation
    
    @rateLinReg = LinearRegression.new
    @rateLinReg.training_data[:x] = x.clone
    @rateLinReg.training_data[:y] = rate_y
    @rateLinReg.normal_equation
    
    respond_to do |format|
       format.js {}
     end
  end
  
  def date_int(date)
    date = date.to_s
    return (Date.new(date[0, 4].to_i, date[4, 2].to_i, date[6, 2].to_i) - Date.new(1970, 01, 01)).to_i
  end
end
