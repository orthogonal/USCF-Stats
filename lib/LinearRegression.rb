class LinearRegression
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
    self.theta = Matrix.build(numFeatures, 1){|row, col| 0}
    puts "Training data: #{training_data[:x].inspect}"
    #feature_scale()
    gradient_descent()      # Now that everything is initialized, run gradient descent.
  end
  
  def result(x)
    return h([1] + x)
  end
  
  def feature_scale()
    for j in 1...training_data[:x][0].length do
      min = 999999.0
      max = -999999.0
      total = 0.0
      for i in 0...training_data[:x].length do
        puts "i, j: #{i}, #{j}  max: #{max} min: #{min} row: #{training_data[:x][i]}"
        if (min > training_data[:x][i][j]) then min = training_data[:x][i][j] end
        if (max < training_data[:x][i][j]) then max = training_data[:x][i][j] end
        total += training_data[:x][i][j]
      end
      avg = total / training_data[:x].length.to_f
      range = max - min
      for i in 0...training_data[:x].length do
        training_data[:x][i][j] = (training_data[:x][i][j].to_f - avg) / range
      end
    end
  end
    
  
  def gradient_descent()
    oldJ = 99999    # Big enough that the learning rate won't get diminished on the first run      
    newJ = J()
    alpha = 0.1    # Learning rate
    run = 0
    maxRun = 100
    while (run < maxRun) do
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
      if (run == maxRun && (oldJ - newJ > 0.001)) then maxRun += 20 end   # Do 20 more if the error is still going down a fair amount.
      if (oldJ < newJ)
        alpha /= 10
        puts "ALPHA: #{alpha}, RUN: #{run}, J: #{newJ}, Theta: #{theta.inspect}"
      end
    end
  end
  
  def J()
    sum = 0
    for i in 0...m
      sum += (h(training_data[:x][i]) - training_data[:y][i][0])**2
    end
    return (1.0 / (2.0 * m)) * sum
  end
  
  def h(x)
    if (x.class != 'Matrix')    # In case it comes in as a row vector or an array
      x = Matrix.rows([x])      # [x] because if it's a row vector we want [[a, b]] to get an array whose first row is x.
    end
    return (x * theta)[0, 0]    # x*theta gives [[n]], return the [0, 0] of that to return the number n.
  end
  
  def normal_equation()       # Use when there are < 1000 training examples
    x = Matrix.rows(self.training_data[:x].map{|row| [1] + row})
    y = Matrix.rows(self.training_data[:y])
    
    if !((x.transpose * x).regular?) then return false end      # If the matrix is singular, use gradient descent instead
    self.theta = (x.transpose * x).inverse * x.transpose * y   # TODO:  Use pseudoinverse
    return true
  end
end