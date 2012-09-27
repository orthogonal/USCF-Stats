class InterfaceController < ApplicationController
  require 'open-uri'
  require 'nokogiri'
  require 'mechanize'
  require 'UscfWebsite'
  require 'json'
  
  def setup
    @tournaments = Array.new
    @sections = Array.new
    @opponents = Array.new
  end
    
  def index
    setup()  
    render(:action => "index")
  end
  
  def tournaments
    setup()
    id = params[:uscf_id].strip
    puts "Request with ID: #{id}"
    if !(id.match(/\d{8}/))
      render :js => ""
      return
    end
    UscfWebsite.get_tournaments(id, @tournaments, @sections)
    obj = {:num => @tournaments.length}
    for i in 0...(@tournaments.length)
      url = "http://main.uschess.org/assets/msa_joomla/#{@tournaments[i].gsub("XtblMain", "XtblPlr")[0, @tournaments[i].rindex('-')]}%03d-#{id}" % @sections[i]
      obj.merge! i => url
    end
    respond_to do |format|
        format.json { render :js => obj.to_json}
    end
  end
  
  def from_tournament
    setup()
    url = params[:url]
    doc = Nokogiri::HTML(open(url))
    links = doc.search("td:nth-child(5) a")
    links.each do |link|
      oppId = link.attr("href")[link.attr("href").index('?') + 1, link.attr("href").length]
      ratings = UscfWebsite.get_actual_ratings_from_id(oppId)
      @opponents << {:name => link.text, :id => oppId, :regular => ratings[:regular], :quick => ratings[:quick]}
    end
    @opponents.uniq!  # Removes duplicates in-place
    @opponents.sort_by!{|item| -item[:regular]}
    @opponents.unshift({:date => url[url.index("?") + 1, url.index("?") + 9]})
    respond_to do |format|
      format.json {render :js => @opponents.to_json}
    end
  end
  
  def complete
    setup()
    stuff = params[:stuff].to_hash
    @opponents = stuff.map{|key, value| value}
    @opponents.uniq!
    @opponents.sort_by!{|item| -item[:regular].to_i}
    
    respond_to do |format|
        format.js {}
    end
  end
  
  
end
