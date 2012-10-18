#encoding: UTF-8
class UscfWebsite
  require "open-uri"
  require "nokogiri"
  require "mechanize"
  
  REGULAR = 0
  QUICK = 1
  ALL = 2
  
  def self.all_games_in_tournament(tournament_id, section, type)
    url = "http://www.uschess.org/assets/msa_joomla/XtblMain.php?#{tournament_id}.#{section}"
    doc = Nokogiri::HTML(open(url))
    crosstable = doc.search("pre").inner_html
    rows = crosstable.split('<a href="XtblPlr.php?')
    rows.shift
    num_players = rows.length
    results = Array.new(num_players){ Array.new(num_players) { Array.new() } }
    rows.each do |row|
      place = row.scan(/>\d+</).first.scan(/\d+/).first.to_i
      id = row.scan(/\?\d{8}">/).first.scan(/\d+/).first.to_i
      name = row.scan(/>[A-Z]+[^<]+</).first.scan(/[A-Z]+[^<]+/).first
      score = row.scan(/a>[^|]+\|\d+\.\d+/)
      puts "SCORE: #{score}"
      score = score.first.scan(/\d+\.\d+/).first.to_f
      games = row.scan(/\|[WDL]\D+\d{1,4}/)
      games.each do |game|
        results[place - 1][place - 1] = [id, name, score]
        res = game.scan(/[WDL]/).first
        opp = game.scan(/\d+/).first.to_i
        results[place - 1][opp - 1] << res
      end
    end
    for i in 0...results.length do
      for j in 0...results[i].length do
        if (i != j)
          total = 0
          if (results[i][j].length == 0)
            results[i][j] = 99  # Impossible result
            next
          end
          results[i][j].each do |wdl|
            if (wdl == 'W')
              total += 1
            elsif (wdl == 'L')
              total -= 1
            end
          end
          results[i][j] = total
        end
      end
    end
    return results
  end
  
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
       for j in 0...names.length
         link = names[j].at_css("a")
         regChanges = regulars[j].text.scan(/\d+{3,4}/) # The 3,4 is to avoid the (P20) case, there will never be a 3-digit provisional.
         quickChanges = quicks[j].text.scan(/\d+{3,4}/)
         if ((type == self::REGULAR && regChanges.length == 0) || (type == self::QUICK && quickChanges.length == 0)) then next end
         section = names[j].at_css("small").text.scan(/\d+/).first.to_i
         name = link.text
         link = link.attributes()["href"].to_s
         tournament_id = link[link.index('?') + 1, (link.index('-') - link.index('?') - 1)]
         date = link[link.index('?') + 1, 8].to_i
         if (regulars[j].text.index("(Unrated)") != nil) then regChanges.unshift(0) end
         if (quicks[j].text.index("(Unrated)") != nil) then quickChanges.unshift(0) end
         if (changes)
           regChanges = (regChanges.length == 0) ? {:pre => nil, :post => nil} : {:pre => regChanges[0].to_i, :post => regChanges[1].to_i}
           quickChanges = (quickChanges.length == 0) ? {:pre => nil, :post => nil} : {:pre => quickChanges[0].to_i, :post => quickChanges[1].to_i}
           result << {:name => name, :id => tournament_id, :section => section, :date => date, :regular => regChanges, :quick => quickChanges}
         else
           result << {:name => name, :id => tournament_id, :section => section, :date => date}
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
  
  def self.get_rating_on_date_from_id(id, date)
    # Date should be ie YYYYMMDD, and an integer
    date = date.to_i
    history = get_rating_history_from_id(id, self::ALL)
    results = {:regular => 0, :quick => 0}
    history.sort_by!{|item| -item[:date]}
    i = 0;
    while (history[i] && history[i][:date] > date)
      i += 1
    end
    if !(history[i]) then return results end   # If the date was off the end of the array, return both as unrated.
    if (history[i][:regular][:post]) then results[:regular] = history[i][:regular][:post] end  # Set both ratings if they exist
    if (history[i][:quick][:post]) then results[:quick] = history[i][:quick][:post] end
    if (!(history[i][:regular][:post]) || !(history[i][:quick][:post])) # At least one will exist
      if (!(history[i][:regular][:post]))
        while (history[i] && !(history[i][:regular][:post]))
          i += 1
        end
        if (history[i]) then return (results[:regular] = history[i][:regular][:post]; results) end
        return results
      else
        while (history[i] && !(history[i][:quick][:post]))
          i += 1
        end
        if (history[i]) then return (results[:quick] = history[i][:quick][:post]; results) end
        return results
      end
    else
      return results
    end
  end
  
  def self.date_of_last_tournament(id)
    tournaments = get_rating_history_from_id(id, self::ALL)
    tournaments.sort_by!{|x| -x[:date]}
    dates = {:regular => nil, :quick => nil}
    i = 0
    while ((!dates[:regular] || !dates[:quick]) && tournaments[i])
      if (!dates[:regular] && tournaments[i][:regular][:post]) then dates[:regular] = tournaments[i][:date] end
      if (!dates[:quick] && tournaments[i][:quick][:post]) then dates[:quick] = tournaments[i][:date] end
      i += 1
    end
    return dates
  end
  
  def self.get_opponents_from_tournament(id, tournament_id, section)
    url = "http://main.uschess.org/assets/msa_joomla/XtblPlr.php?#{tournament_id}-%03d-#{id}" % section
    doc = Nokogiri::HTML(open(url))
    links = doc.search("td:nth-child(5) a") # International events don't have the players listed as links, just 'ERROR'
    
    result = Array.new
    
    links.each do |link|
      oppId = link.attr("href")[link.attr("href").index('?') + 1, 8].to_i
      now_ratings = self.get_actual_ratings_from_id(oppId)
      then_ratings = self.get_rating_changes_from_tournament(oppId, tournament_id, section) # That method needs to be re-done
      result << {:id => oppId, :name => link.text, :now => now_ratings, :then => then_ratings}
    end
    
    return result
    
  end
  
  def self.get_results_against_opponents_from_tournament(id, tournament_id, section)
    url = "http://main.uschess.org/assets/msa_joomla/XtblPlr.php?#{tournament_id}-%03d-#{id}" % section
    doc = Nokogiri::HTML(open(url))
    links = doc.search("td:nth-child(5) a") # International events don't have the players listed as links, just 'ERROR'
    
    result = Array.new
    
    links.each do |link|
      obj = {:wdl => nil, :regular => -1, :quick => -1, :name => ""}
      tds = link.parent.parent.children.to_a
      tds.delete_if{|td| td.text.scan(/[A-Za-z0-9]/).length == 0}
      
      obj[:wdl] = tds[0].text.scan(/[WDL]{1}/).first
      obj[:name] = tds[4].text.scan(/[A-Z ]+[A-Z]/).first
      
      if ((tds[2].text.index("R:")) != nil)
        if ((tds[2].text.scan(/R: Unrated/)).length > 0)  # Player's initial rating was unrated, use the post rating
          obj[:regular] = tds[3].text.scan(/\d+{3,4}/).first # Regardless of quick or regular, regular is first.
        else
          obj[:regular] = tds[2].text.scan(/R:[ ]+\d+{3,4}/).first.scan(/\d+{3,4}/).first
        end
      end
      
      if ((tds[2].text.index("Q:")) != nil)
        if ((tds[2].text.scan(/Q: Unrated/)).length > 0) 
          if ((tds[2].text.index("R:")) == nil)   # If it was dual-rated, the index of R will not be nil, and we use the second number.
            obj[:quick] = tds[3].text.scan(/\d+{3,4}/).first
          else
            obj[:quick] = tds[3].text.scan(/\d+{3,4}/).last
          end
        else
          obj[:quick] = tds[2].text.scan(/Q:[ ]+\d+{3,4}/).first.scan(/\d+{3,4}/).first
        end
      end
      
      result << obj 
    end
    
    return result
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
      regular_bit = changes.text.scan(/R:[^-]+->\s*\d{3,4}/)
      blocks = (regular_bit.length > 0) ? regular_bit.first.scan(/\d+{3,4}/) : [0, 0]
      pre = (blocks.length > 1) ? blocks[0] : 0
      post = (blocks.length > 1) ? blocks[1] : blocks[0]
      rc[:regular] = {:pre => pre, :post => post}
    end
    if (changes.text.index("Q:") != nil)
      quick_bit = changes.text.scan(/Q:[^-]+->\s*\d{3,4}/)
      blocks = (quick_bit.length > 0) ? quick_bit.first.scan(/\d+{3,4}/) : [0, 0]
      pre = (blocks.length > 1) ? blocks[0] : 0
      post = (blocks.length > 1) ? blocks[1] : blocks[0]
      rc[:quick] = {:pre => pre, :post => post}
    end
    return rc
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



    
end