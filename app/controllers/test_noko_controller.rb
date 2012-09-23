class TestNokoController < ApplicationController
  require 'open-uri'
  require 'nokogiri'
  require 'mechanize'
  
  def index
    doc = Nokogiri::HTML(open("http://main.uschess.org/assets/msa_joomla/MbrLst.php?latham"))
    list = doc.at_css("pre").inner_html
    firstNumber = list.index(/\d/)
    list = list[firstNumber, list.length]
    
    # Get all the ratings by splitting on <a> tag elements and then sub-splitting on spaces.  Spaces are consistent.
    infos = list.split(/<a[^>]*>[^<]*<\/a>/)[0...-1]    # There will be a nil element at the end because of how the USCF website is built
    @ratings = Array.new
    infos.each do |info| 
      @ratings << info.split(' ')[3].strip
    end

    # Get all the names by getting just <a> tag elements and then killing off the actual tags to just get the content.
    names = list.scan(/<a[^>]*>[^<]*<\/a>/)
    puts names
    @names = Array.new
    names.each do |name|
      @names << name.gsub(/<[^>]*>/, '').titleize.strip
    end
      
    render(:action => "index")
  end
  
  def opponents
    agent = Mechanize.new
    @tournaments = Array.new
    @sections = Array.new
    
    # Get a mechanize object representing the USCF members page, search for 'Cusick', and click on the link with Doc's name.
    agent.get("http://main.uschess.org/assets/msa_joomla/MbrLst.php")
    form = agent.page.form_with(:name => "form1")
    form.eMbrKey = "cusick"
    form.submit
    agent.page.link_with(:text => "CUSICK, MICHAEL ").click
    
    # Get my USCF ID from the URI and use it to go to Doc's tournament history
    url = agent.page.uri.to_s
    id = url[url.index('?') + 1, url.length]
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
          @tournaments << link.attributes()["href"].to_s
          @sections << section.text.scan(/\d+/).first.to_i
        end
      end
    end
    
    @opponents = Array.new
    
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
