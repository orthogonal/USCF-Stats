class TestNokoController < ApplicationController
  require 'open-uri'
  @text = ""
  def index
    open("http://main.uschess.org/assets/msa_joomla/MbrLst.php?latham") {|f|
        f.each_line {|line| p line}
    }
    render(:action => "index")
  end
end
