class LinearRegression
  require 'Matrix'
  
  attr_accessor :training_data
  
  def initialize()
    self.training_data = {:in => Array.new, :out => Array.new}
  end
  
  def best_fit()
    
  end
  
  def J()
    m = self.training_data[:in].length
  end
  
  def normal_equation()       # Use when there are < 1000 training examples
    m = self.training_data[:in].length
    n = self.training_data[:in].first.length
    
    zzzz = [1] + self.training_data[:in].first
    puts "ZZZZ: #{zzzz}"
    x = Matrix.rows(self.training_data[:in].map{|row| [1] + row})
    y = Matrix.rows(self.training_data[:out])
    
    theta = (x.transpose * x).inverse * x.transpose * y
    
    return theta.to_a
  end
end