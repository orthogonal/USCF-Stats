class ExperienceController < ApplicationController
  require 'UscfWebsite'
  require 'UscfMath'
  def index
    @result = []
    ids = [12842311, 13666146, 12895924, 13362808, 12929115]
    ids.each do |uscf_id|
      history = UscfWebsite.get_rating_history_from_id(uscf_id, UscfWebsite::REGULAR)
      history.reverse!
      total = 0
      data = []
      history.each do |event|
        more = UscfWebsite.num_games_in_tournament(event[:id], event[:section], UscfWebsite::REGULAR, uscf_id)
        if (more != 0)
          total += more
          data << {:name => event[:name], :performance => performance(uscf_id, event[:id], event[:section]), :rating => event[:regular][:post], :x => total}
        end
      end
      @result << {:id => uscf_id, :data => data}
    end
    puts @result
    render :action => "index"
  end
  
  def performance(uscf_id, tournament, section)
    tourn_result = UscfWebsite.get_results_against_opponents_from_tournament(uscf_id, tournament, section)
    results = Array.new
    tourn_result.each do |row|
      results << {:wdl => row[:wdl], :opp => (session[:type] == UscfWebsite::REGULAR ? row[:regular].to_i : row[:quick].to_i)}
    end
    return UscfMath.performance(results)
  end
  
end
