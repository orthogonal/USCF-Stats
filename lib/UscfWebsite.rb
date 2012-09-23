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
      puts "i is #{i}"
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
  
end