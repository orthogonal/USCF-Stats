class LogisticRegression
  require 'matrix'
  
  attr_accessor :training_data
  attr_accessor :theta
  attr_accessor :m
  attr_accessor :numFeatures
  
  def initialize()
    self.training_data = {:x => Array.new, :y => Array.new}
    self.theta = nil
    self.m = nil
    self.numFeatures = nil
  end
  
  def train()
    self.training_data[:x] = self.training_data[:x].clone           # Since we're about to modify it, get rid of any outside references
    x = Matrix.rows(self.training_data[:x].map!{|row| [1] + row})   # Add x_0 = 1 to the training data
    y = Matrix.rows(training_data[:y])
    self.m = training_data[:x].length
    self.numFeatures = x.column_size
    self.theta = Matrix.zero(numFeatures, 1)
    gradient_descent()      # Now that everything is initialized, run gradient descent.
  end
  
  def result(x)
    return h([1] + x) < 0.5 ? 0 : 1
  end
  
  def gradient_descent()
    oldJ = 99999    # Big enough that the learning rate won't get diminished on the first run      
    newJ = J()
    alpha = 1.0     # Learning rate
    run = 0
    while (run < 100) do
      tmpTheta = Array.new
      for j in 0...numFeatures do
        sum = 0
        for i in 0...m do
          sum += ((h(training_data[:x][i]) - training_data[:y][i][0]) * training_data[:x][i][j])
        end
        tmpTheta[j] = Array.new
        tmpTheta[j][0] = theta[j, 0] - (alpha / m) * sum  # Alpha * partial derivative of J with respect to theta_j
      end
      self.theta = Matrix.rows(tmpTheta)
      oldJ = newJ
      newJ = J()
      run += 1
      if (run == 100 && (oldJ - newJ > 0.001)) then run -= 20 end   # Do 20 more if the error is still going down a fair amount.
      if (oldJ < newJ)
        alpha /= 10
      end
    end
  end
  
  def J()
    sum = 0
    for i in 0...m
      #puts "i: #{i}, m: #{m}, x: #{training_data[:x][i]}, y: #{training_data[:y][i][0]}, sum: #{sum}"
      sum += ((training_data[:y][i][0] * Math.log(h(training_data[:x][i]))) 
          + ((1 - training_data[:y][i][0]) * Math.log(1 - h(training_data[:x][i]))))
      #puts "Y: #{training_data[:y][i]} H: #{h(training_data[:x][i])}  Xi:  #{training_data[:x][i].inspect}  i: #{i}  Cost Function: #{    ((training_data[:y][i][0] * Math.log(h(training_data[:x][i]))) 
             # + ((1 - training_data[:y][i][0]) * Math.log(1 - h(training_data[:x][i]))))}"
    end
    return (-1.0 / m) * sum
  end
  
  def h(x)
    if (x.class != 'Matrix')    # In case it comes in as a row vector or an array
      x = Matrix.rows([x])      # [x] because if it's a row vector we want [[a, b]] to get an array whose first row is x.
    end
    x = x.transpose   # x is supposed to be a column vector, and theta^ a row vector, so theta^*x is a number.
    return g((theta.transpose * x)[0, 0])  # theta^ * x gives [[z]], so get [0, 0] of that for the number z.
  end
  
  def g(z)
    #puts "Z: #{z}, e^-Z: #{Math.exp(-z)}, G: #{1.0 / (1.0 + Math.exp(-z))}, Theta: #{theta.inspect}"
    tmp = 1.0 / (1.0 + Math.exp(-z))   # Sigmoid function
    if (tmp == 1.0) then tmp = 0.99999 end    # These two things are here because ln(0) DNE, so we don't want to do ln(1 - 1.0) or ln(0.0)
    if (tmp == 0.0) then tmp = 0.00001 end
    return tmp
  end
end