class TestNokoController < ApplicationController
  require 'open-uri'
  require 'nokogiri'
  
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
end
