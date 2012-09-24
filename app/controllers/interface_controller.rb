class InterfaceController < ApplicationController
  require 'open-uri'
  require 'nokogiri'
  require 'mechanize'
  require 'UscfWebsite'
  
  def setup
    @tournaments = Array.new
    @sections = Array.new
    @opponents = Array.new
  end
    
  def index
    setup()  
    render(:action => "index")
  end
  
  def go
    setup()
    id = params[:uscf_id]
    UscfWebsite.get_tournaments(id, @tournaments, @sections)

    # For each tournament, go to the URL that shows who Doc played in that tournament, and scrape up the names of the players.
    for i in 0...(@tournaments.length)
      url = "http://main.uschess.org/assets/msa_joomla/#{@tournaments[i].gsub("XtblMain", "XtblPlr")[0, @tournaments[i].rindex('-')]}%03d-#{id}" % @sections[i]
      puts "URL: #{url}"
      doc = Nokogiri::HTML(open(url))
      links = doc.search("td:nth-child(5) a")
      links.each do |link|
        oppId = link.attr("href")[link.attr("href").index('?') + 1, link.attr("href").length]
        ratings = UscfWebsite.get_actual_ratings_from_id(oppId)
        @opponents << {:name => link.text, :id => oppId, :regular => ratings[:regular], :quick => ratings[:quick]}
      end
      @opponents.uniq!  # Removes duplicates in-place
      @opponents.sort_by!{|item| -item[:regular]}
    end
    
    respond_to do |format|
        format.js {}
    end
  end
  
  
end
