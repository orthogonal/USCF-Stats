class LinearRegression
  require 'matrix'
  
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
    x = Matrix.rows(self.training_data[:in].map{|row| [1] + row})
    y = Matrix.rows(self.training_data[:out])
    
    theta = (x.transpose * x).inverse * x.transpose * y   # TODO:  Use pseudoinverse
    
    return theta.to_a
  end
end