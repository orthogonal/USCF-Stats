class DeltasController < ApplicationController
  require 'UscfWebsite'
  require 'LogisticRegression'
  def index
    render(:action => "index")
  end
  
  def rating_history
    id = params[:uscf_id].strip
    type = (params[:type] == "regular") ? UscfWebsite::REGULAR : UscfWebsite::QUICK
    session[:type] = type
    if !(id.match(/\d{8}/))
      render :js => ""
      return
    end
    history = UscfWebsite.get_rating_history_from_id(id, type)
    result = Array.new;
    for i in 0...history.length do
      result << {:id => history[i][:id], :section => history[i][:section], 
        :rating => (type == UscfWebsite::REGULAR ? (history[i][:regular][:pre] != 0) ? history[i][:regular][:pre] : history[i][:regular][:post]
                                                 : (history[i][:quick][:pre] != 0) ? history[i][:quick][:pre] : history[i][:quick][:post])}
    end
    render :js => result.to_json
  end
  
  def opp_results
    result = Array.new
    tourn_result = UscfWebsite.get_results_against_opponents_from_tournament(params[:uscf_id], params[:tournament], params[:section])
    tourn_result.each do |row|
      result << {:wdl => row[:wdl], :rating => params[:rating].to_i, 
                :delta => (session[:type] == UscfWebsite::REGULAR ? row[:regular].to_i - params[:rating].to_i : row[:quick].to_i - params[:rating].to_i),
                :name => (row[:name])}
    end
    
    render :js => result.to_json
  end
  
  def build_chart
    @data = params[:results].to_hash.map{|key, value| value}
    @data.map!{|record| record.symbolize_keys}
    
    # Build Logistic Regression input data
    x = Array.new
    win_y = Array.new
    draw_y = Array.new
    for i in 0...@data.length do
      x[i] = Array.new
      win_y[i] = Array.new
      draw_y[i] = Array.new
      x[i][0] = @data[i][:rating].to_i
      x[i][1] = @data[i][:delta].to_i
      win_y[i][0] = (@data[i][:wdl] == "W") ? 1 : 0
      draw_y[i][0] = (@data[i][:wdl] == "L") ? 0 : 1
    end
    
    # Train two logistic regression classifiers
    @winLogReg = LogisticRegression.new
    @winLogReg.training_data[:x] = x.clone
    @winLogReg.training_data[:y] = win_y
    @winLogReg.train
    @drawLogReg = LogisticRegression.new
    @drawLogReg.training_data[:x] = x.clone
    @drawLogReg.training_data[:y] = draw_y
    @drawLogReg.train
    
    respond_to do |format|
      format.js {}
    end
  end
end
