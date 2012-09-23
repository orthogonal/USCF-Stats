class TestNokoController < ApplicationController
  require 'open-uri'
  require 'nokogiri'
  require 'mechanize'
  require 'uscfwebsite'
  
  def setup
    @names = Array.new
    @ratings = Array.new
    @tournaments = Array.new
    @sections = Array.new
    @opponents = Array.new
  end
    
  def index
    setup()
    doc = Nokogiri::HTML(open("http://main.uschess.org/assets/msa_joomla/MbrLst.php?latham"))
    list = doc.at_css("pre").inner_html
    firstNumber = list.index(/\d/)
    list = list[firstNumber, list.length]
    
    # Get all the ratings by splitting on <a> tag elements and then sub-splitting on spaces.  Spaces are consistent.
    infos = list.split(/<a[^>]*>[^<]*<\/a>/)[0...-1]    # There will be a nil element at the end because of how the USCF website is built
    infos.each do |info| 
      @ratings << info.split(' ')[3].strip
    end

    # Get all the names by getting just <a> tag elements and then killing off the actual tags to just get the content.
    names = list.scan(/<a[^>]*>[^<]*<\/a>/)
    puts names
    names.each do |name|
      @names << name.gsub(/<[^>]*>/, '').titleize.strip
    end
      
    render(:action => "index")
  end
  
  def opponents
    setup()
    ratings = UscfWebsite.get_published_ratings_from_id(14890336)
    puts "REGULAR: #{ratings[:regular]}\nQUICK: #{ratings[:quick]}"
    ratings = UscfWebsite.get_actual_ratings_from_id(14890336)
    puts "REGULAR: #{ratings[:regular]}\nQUICK: #{ratings[:quick]}"
    agent = UscfWebsite.player_search_result("cusick")
    agent.page.link_with(:text => "CUSICK, MICHAEL ").click
    
    # Get my USCF ID from the URI and use it to go to Doc's tournament history
    url = agent.page.uri.to_s
    id = UscfWebsite.get_id_from_profile_url(url)
    
    UscfWebsite.get_tournaments(id, @tournaments, @sections)
    puts "TOURNAMENTS: #{@tournaments}"
    
    # For each tournament, go to the URL that shows who Doc played in that tournament, and scrape up the names of the players.
    for i in 0...(@tournaments.length)
      url = "http://main.uschess.org/assets/msa_joomla/#{@tournaments[i].gsub("XtblMain", "XtblPlr")[0, @tournaments[i].rindex('-')]}%03d-#{id}" % @sections[i]
      puts "URL: #{url}"
      doc = Nokogiri::HTML(open(url))
      links = doc.search("td:nth-child(5) a")
      links.each do |link|
        @opponents << link.text
      end
      @opponents.uniq!  # Removes duplicates in-place
    end
    
    render(:action => "opponents")
  end
end
