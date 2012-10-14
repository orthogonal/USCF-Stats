class UscfMath
  def self.performance(results)
    numGames = results.length
    score = 0
    for i in 0...numGames
      if (results[i][:wdl] != 'L')
        score += (results[i][:wdl] == 'W') ? 1 : 0.5
      end
    end
    low = high = last = 0
    x = 4000
    if (score == 0) then return [100, results.min_by{|r| r[:opp]}[:opp] - 400].max end
    if (score == numGames) then return [2700, results.max_by{|r| r[:opp]}[:opp] + 400].min end
    while ((x - last).abs > 0.1) do
      last = x
      n = 0
      for i in 0...numGames
        delta = results[i][:opp] - x
        n += ((Math.exp(Math.log(10) * (delta/400.0)) + 1.0)**-1)
      end
      if ((n - score) > 0)
        low = x
        x = (x + high) / 2.0
      else
        high = x
        x = (x + low) / 2.0
      end
    end
    return x
  end
end