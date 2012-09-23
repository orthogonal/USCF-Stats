class UscfWebsite
  require "open-uri"
  require "nokogiri"
  require "mechanize"
  
  def self.get_tournaments(id, tournaments, sections)
    doc = Nokogiri::HTML(open("http://main.uschess.org/assets/msa_joomla/MbrDtlTnmtHst.php?#{id}"))
    
    # Figure out how many pages of tournament records Doc has
    pages = doc.search("nobr a")
    pages = (pages.length != 0 ? pages.length : 1)
    
    # Go through each page, get all the blocks with tournament information and save the name and section Doc played in.
    for i in 1...(pages + 1)
      if (i != 1) then doc = Nokogiri::HTML(open("http://main.uschess.org/assets/msa_joomla/MbrDtlTnmtHst.php?#{id}.#{i}")) end
      blocks = doc.search("td:nth-child(2)")
      blocks.each do |block|
        link = block.at_css("a")
        if (link != nil)
          section = block.at_css("small")
          tournaments << link.attributes()["href"].to_s
          sections << section.text.scan(/\d+/).first.to_i
        end
      end
    end
  end
  
  def self.get_id_from_profile_url(url)
    url = (url.class() == String ? url : url.to_s)
    return url[url.index('?') + 1, url.length]
  end
  
  def self.player_search_result(term)
    agent = Mechanize.new
    
    # Get a mechanize object representing the USCF members page and search for the term
    agent.get("http://main.uschess.org/assets/msa_joomla/MbrLst.php")
    form = agent.page.form_with(:name => "form1")
    form.eMbrKey = term
    form.submit
    return agent
  end
  
  def self.get_published_ratings_from_id(id)
    doc = Nokogiri::HTML(open("http://main.uschess.org/assets/msa_joomla/MbrDtlMain.php?#{id}"))
    ratings = {:regular => 0, :quick => 0}
    rowTitles = doc.search("td td td:nth-child(1)")
    rowTitles.each do |node|
      if node.text.include?("Regular Rating")
        ratings[:regular] = node.next_sibling.next_sibling.text.strip
        if (ratings[:regular].include?("\n")) then ratings[:regular] = ratings[:regular][0, ratings[:regular].index("\n")] end # Date
        if (ratings[:regular].include?(" ")) then ratings[:regular] = ratings[:regular][0, ratings[:regular].index(" ")] end # Prov.
        if (ratings[:regular].include?("Unrated")) then ratings[:regular] = 0 end # Unr.
      elsif node.text.include?("Quick Rating")
        ratings[:quick] = node.next_sibling.next_sibling.text.strip
        if (ratings[:quick].include?("\n")) then ratings[:quick] = ratings[:quick][0, ratings[:quick].index("\n")] end # Date
        if (ratings[:quick].include?(" ")) then ratings[:quick] = ratings[:quick][0, ratings[:quick].index(" ")] end # Prov.
        if (ratings[:quick].include?("Unrated")) then ratings[:quick] = 0 end # Unr.
      end
    end
    return ratings
  end
  
  def self.get_actual_ratings_from_id(id)
    doc = Nokogiri::HTML(open("http://main.uschess.org/assets/msa_joomla/MbrDtlTnmtHst.php?#{id}"))
    ratings = {:regular => 0, :quick => 0}
    pages = doc.search("nobr a")
    pages = (pages.length != 0 ? pages.length : 1)
    
    for i in 1...(pages + 1)
      if (i != 1) then doc = Nokogiri::HTML(open("http://main.uschess.org/assets/msa_joomla/MbrDtlTnmtHst.php?#{id}.#{i}")) end
      regBlocks = doc.search("td:nth-child(3)")
      quickBlocks = doc.search("td:nth-child(4)")
      
      regBlocks.each do |block|
        if (block.text.include?("=>") && ratings[:regular] == 0)
          ratings[:regular] = block.text[block.text.index("=>") + 2, block.text.length].strip.to_i
          break
        end
      end
      
      quickBlocks.each do |block|
        if (block.text.include?("=>") && ratings[:quick] == 0)
          ratings[:quick] = block.text[block.text.index("=>") + 2, block.text.length].strip.to_i
          break
        end
      end
      if (ratings[:quick] > 0 && ratings[:regular] > 0) then break end
    end
    return ratings
  end
end