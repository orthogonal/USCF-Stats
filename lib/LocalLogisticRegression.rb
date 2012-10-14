class LocalLogisticRegression
  require 'Matrix'
  
  attr_accessor :trainingData, :k
  
  def initialize(k)
    self.trainingData = {:in => Array.new, :out => Array.new}
    self.k = k
  end
  
  def b(xq, times)
    newton_raphson((Matrix.build(xq.length + 1, 1){0}).to_a, xq, times)
  end
  
  def newton_raphson(b, xq, times)
    #if (times == 0) then return b end
    w = Matrix.build(trainingData[:in].length, trainingData[:in].length){|row, col| (row == col) ? weight(xq, row) * pi_prime(row, b) : 0}
    x = Matrix.rows(trainingData[:in].each{|row| [1] + row})
    e = Matrix.build(1, trainingData[:in].length){|row, col| weight(xq, row)}
    additive = (x.transpose * w * x).inverse * x.transpose * w
    b = (Matrix.rows(b) + additive)
    puts "B: #{b}"
  end
  
  def pi_prime(i, b)
    xb = (Matrix.rows([[1] + @trainingData[:in][i]]) * Matrix.rows(b))[0, 0]
    return (Math.exp(-1 * xb)/((1 + Math.exp(-1 * xb))**2))
    #second = [[1]] + [@trainingData[:in][i]].transpose
    #w = Matrix.rows([[first]]) * Matrix.rows(second)
    #puts "W: #{w}"
  end
  
  def weight(xq, i)
    xi = @trainingData[:in][i]
    return Math.exp(-(euclidean_distance(xi, xq)**2)/(k**2))
  end
    
  def euclidean_distance(xi, xq)
    n = xi.length
    sum = 0
    for i in 0...n
      sum += (xi[i] - xq[i])**2
    end
    return Math.sqrt(sum)
  end
end