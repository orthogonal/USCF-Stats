class LinearRegression
  require 'matrix'
  
  attr_accessor :training_data
  
  def initialize()
    self.training_data = {:in => Array.new, :out => Array.new}
  end
  
  def gradient_descent()
    x = Matrix.rows(self.training_data[:in].map{|row| [1] + row})
    y = Matrix.rows(self.training_data[:out])
    alpha = 0.001
    theta = Array.new
    n = self.training_data[:in].first.length
    m = self.training_data[:in].length
    
    for j in 0...n
      theta[j] = 0
    end
    
    oldcost = 99999999
    while(true)
      tmp = theta
      for j in 0...n
        tmp[j] = tmp[j] - alpha * dj(x, m, theta)
      end
      theta = tmp
      cost = J(theta)
      if (oldcost - cost) < 0.001
        break
      elsif (oldcost - cost) < 0
        alpha = alpha / 3
      end
      oldcost = cost
    end
    return theta
    
  end
  
  def dj(x, m, theta)
    tmp = 0
    for i in 0...m
      tmp += ((theta.transpose * x[i]) - y[i].first) * x[i][j]
    end
    return tmp / m
  end
  
  def J()
    m = self.training_data[:in].length
    tmp = 0
    for i in 1..m do
      tmp += ((theta.transpose * x) - y)**2
    end
    return (1 / (2 * m)) * tmp
  end
  
  def normal_equation()       # Use when there are < 1000 training examples
    x = Matrix.rows(self.training_data[:in].map{|row| [1] + row})
    y = Matrix.rows(self.training_data[:out])
    
    theta = (x.transpose * x).inverse * x.transpose * y   # TODO:  Use pseudoinverse
    
    return theta.to_a
  end
end