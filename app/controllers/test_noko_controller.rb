class TestNokoController < ApplicationController
  
  
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
