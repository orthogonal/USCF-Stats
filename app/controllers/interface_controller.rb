class InterfaceController < ApplicationController
  require 'open-uri'
  require 'nokogiri'
  require 'mechanize'
  require 'UscfWebsite'
  require 'json'
  
  def setup_tan
    @result = Array.new
  end
    
  def index
    setup_tan()
    render(:action => "index")
  end
  
  def tan_tournaments
    id = params[:uscf_id].strip
    type = (params[:type] == "regular") ? UscfWebsite::REGULAR : UscfWebsite::QUICK
    if !(id.match(/\d{8}/))
      render :js => ""
      return
    end
    history = UscfWebsite.get_rating_history_from_id(id.to_i, type)
    obj = {:num => history.length}
    for i in 0...history.length
      tournament_id = history[i][:id]
      section = history[i][:section]
      date = history[i][:date]
      name = history[i][:name]
      regular = history[i][:regular][:pre]
      quick = history[i][:quick][:pre]
      obj.merge! i => {:date => date, :tournament_id => tournament_id, :section => section, :name => name, :regular => regular, :quick => quick}
    end
    respond_to do |format|
        format.json { render :js => obj.to_json}
    end
  end
  
  def tan_opponents
    id = params[:uscf_id].strip.to_i
    tournament = params[:tournament].strip.to_i
    section = params[:section].strip.to_i
    opponents = UscfWebsite.get_opponents_from_tournament(id, tournament, section)
    opponents.each do |opponent|
      opponent.merge! :date => tournament.to_s[0,8]
    end
    respond_to do |format|
      format.json {render :js => opponents.to_json}
    end
  end
  
  def tan_complete
    setup_tan()
    stuff = params[:stuff].to_hash
    opponents = stuff.map{|key, value| value}
    opponents.sort_by!{|item| -item[:id].to_i}
    
    # Data format is an array of hashes with id, name, date, now{regular, quick}, then{regular{pre, post}, quick{pre, post}}
    current_id = opponents.first[:id].to_i
    this_opponent = Array.new
    
    result = Array.new
    opponents.each do |opponent|
      if (opponent[:id].to_i == current_id)
        this_opponent << opponent
      else  # If the id is different, it's a new opponent, so process the data for the current one. this_opponent is never empty.
        this_opponent.sort_by!{|record| record[:date].to_i}
        new_opponent = {:name => this_opponent.first[:name], 
                        :id => current_id,
                        :plays => this_opponent.length,
                        :now => this_opponent.first[:now],
                        :first => {:date => this_opponent.first[:date], 
                                  :ratings => 
          {:regular => (this_opponent.first[:then][:regular] != "") ? this_opponent.first[:then][:regular][:pre] : -1,
           :quick => (this_opponent.first[:then][:quick] != "") ? this_opponent.first[:then][:quick][:pre] : -1}
                                  },
                        :last =>  {:date => this_opponent.last[:date], 
                                    :ratings => 
          {:regular => (this_opponent.last[:then][:regular] != "") ? this_opponent.last[:then][:regular][:pre] : -1,
           :quick => (this_opponent.last[:then][:quick] != "") ? this_opponent.last[:then][:quick][:pre] : -1}
                                    }
                        }
        @result << new_opponent
        this_opponent = [opponent]
        current_id = opponent[:id].to_i
      end
    end
    @result.sort_by!{|record| -record[:now][:regular].to_i}
    respond_to do |format|
        format.js {}
    end
  end
  
end
