class InterfaceController < ApplicationController
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
    @test = "Nope"
  end
    
  def index
    setup()  
    render(:action => "index")
  end
  
  def go
    @test = "Hello you"
    respond_to do |format|
        format.html { render :partial => 'test', :locals => {:test => @test} }
        format.js {}
    end
  end
  
  
end
