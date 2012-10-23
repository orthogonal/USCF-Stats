class ExperienceController < ApplicationController
  require 'uscfwebsite'
  require 'uscfmath'
  def index
    history = UscfWebsite.get_rating_history_from_id(12842311, UscfWebsite::REGULAR)
    history.reverse!
    total = 0
    @result = []
    history.each do |event|
      total += UscfWebsite.num_games_in_tournament(event[:id], event[:section], UscfWebsite::REGULAR, 12842311)
      @result << {:name => event[:name], :performance => performance(event[:id], event[:section]), :rating => event[:regular][:post], :x => total}
    end
    puts @result
    render :action => "index"
  end
  
  def performance(tournament, section)
    tourn_result = UscfWebsite.get_results_against_opponents_from_tournament(12842311, tournament, section)
    results = Array.new
    tourn_result.each do |row|
      results << {:wdl => row[:wdl], :opp => (session[:type] == UscfWebsite::REGULAR ? row[:regular].to_i : row[:quick].to_i)}
    end
    return UscfMath.performance(results)
  end
  
end
