#encoding: UTF-8
class UscfWebsite
  require "open-uri"
  require "nokogiri"
  require "mechanize"
  
  REGULAR = 0
  QUICK = 1
  ALL = 2
  
  def self.get_player_name_from_id(id)
    doc = Nokogiri::HTML(open("http://main.uschess.org/assets/msa_joomla/MbrDtlMain.php?#{id}"))
    header = doc.at_css("font b")
    name = header.text.scan(/[A-Z][A-Z\s]+/)
    return name
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
  
  def self.get_tournaments_from_id(id, type)
    return self.tournament_history(id, type, false)
  end
  
  def self.get_rating_history_from_id(id, type)
    return self.tournament_history(id, type, true)
  end
  
  def self.tournament_history(id, type, changes)
    doc = Nokogiri::HTML(open("http://main.uschess.org/assets/msa_joomla/MbrDtlTnmtHst.php?#{id}"))
    
    # Figure out how many pages of tournament records the player has
    pages = doc.search("nobr a")
    pages = (pages.length != 0 ? pages.length : 1)
    
    result = Array.new
    
    # Go through each page, get all the blocks with tournament information, add requested data to return array
    for i in 1...(pages + 1)
       if (i != 1) then doc = Nokogiri::HTML(open("http://main.uschess.org/assets/msa_joomla/MbrDtlTnmtHst.php?#{id}.#{i}")) end
       names = doc.search("td:nth-child(2)")
       names.shift    # This selector grabs an extra blank td from somewhere else on the page as its first item
       names.shift    # You have to shift twice because it's a Nokogiri Nodeset, not an array, so you can't do shift(2)
       regulars = doc.search("td:nth-child(3)")
       regulars.shift # Everything shifts once to get rid of the column header
       quicks = doc.search("td:nth-child(4)")
       quicks.shift
       for j in 0...(names.length - 1)
         link = names[j].at_css("a")
         regChanges = regulars[j].text.scan(/\d+/)
         quickChanges = quicks[j].text.scan(/\d+/)
         if ((type == self::REGULAR && quickChanges.length != 0) || (type == self::QUICK && regularChanges.length != 0)) then next end
         section = names[j].at_css("small").text.scan(/\d+/).first.to_i
         name = link.text
         link = link.attributes()["href"].to_s
         id = link[link.index('?') + 1, (link.index('-') - link.index('?') - 1)]
         date = link[link.index('?') + 1, 8]
         if (changes)
           regChanges = (regChanges.length == 0) ? {:pre => nil, :post => nil} : {:pre => regChanges[0].to_i, :post => regChanges[1].to_i}
           quickChanges = (quickChanges.length == 0) ? {:pre => nil, :post => nil} : {:pre => quickChanges[0].to_i, :post => quickChanges[1].to_i}
           result << {:name => name, :id => id, :date => date, :regular => regChanges, :quick => quickChanges}
         else
           result << {:name => name, :id => id, :date => date}
         end
       end 
    end
    return result
  end
  
  def self.get_peak_rating_from_id(id, type)
    history = get_rating_history_from_id(id, type)
    history.map!{|x| x[:regular][:post] ||= 0; x[:quick][:post] ||= 0; x}
    result = {:regular => nil, :quick => nil}
    if (type != self::QUICK && history.length > 0)
       history.sort_by!{|item| -item[:regular][:post]}
       result[:regular] = history.first[:regular][:post]
    end
    if (type != self::REGULAR && history.length > 0)
       history.sort_by!{|item| -item[:quick][:post]}
       result[:quick] = history.first[:quick][:post]
    end
    return result
  end
  
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
  
  def self.get_rating_changes_from_tournament(uscf_id, tournament_id, section)
    url = "http://main.uschess.org/assets/msa_joomla/XtblPlr.php?#{tournament_id}-%03d-#{uscf_id}" % section
    doc = Nokogiri::HTML(open(url))
    i = 0
    tds = doc.search("td")
    td = tds[i]
    while (td.text.downcase.index("rating") == nil || td.text.downcase.index("rating") > 5) do
      i += 1
      td = tds[i]
    end
    changes = td.next_element.next_element
    rc = {:regular => nil, :quick => nil}
    if (changes.text.index("R:") != nil)
      regular_bit = changes.text.scan(/R:\s+\d+\D+\d+/)
      blocks = (regular_bit.length > 0) ? regular_bit.first.scan(/\d+/) : [0, 0]
      pre = blocks[0]
      post = blocks[1]
      rc[:regular] = {:pre => pre, :post => post}
    end
    if (changes.text.index("Q:") != nil)
      quick_bit = changes.text.scan(/Q:\s+\d+\D+\d+/)
      blocks = (quick_bit.length > 0) ? quick_bit.first.scan(/\d+/) : [0, 0]
      pre = blocks[0]
      post = blocks[1]
      rc[:quick] = {:pre => pre, :post => post}
    end
    return rc
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