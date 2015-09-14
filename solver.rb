#!/usr/local/bin/ruby

#
# nlsolve.rb
# An example for solving nonlinear algebraic equation system.
#

# require 'r/comfort.rb'
require "bigdecimal"
require "bigdecimal/math"
require "bigdecimal/newton"

include Newton

class Function

  def initialize()
    @zero = BigDecimal::new("0.0")
    @one  = BigDecimal::new("1.0")
    @two  = BigDecimal::new("2.0")
    @ten  = BigDecimal::new("10.0")
    @eps  = BigDecimal::new("1.0e-1")
  end

  def zero;@zero;end

  def one ;@one ;end

  def two ;@two ;end

  def ten ;@ten ;end

  def eps ;@eps ;end

  def set_vars(t, rh, mrt, va)
    @t = BigDecimal.new(t.to_f.to_s)
    @rh = BigDecimal.new(rh.to_f.to_s)
    @mrt = BigDecimal.new(mrt.to_f.to_s)
    @va = BigDecimal.new(va.to_f.to_s)
  end

  def values(x) # <= defines functions solved  
    f = [RG::Comfort.utci(x[0], @rh / 100.0, @mrt, @va) - 26.0]    
    f
  end
end


class Function2

  def initialize()
    @zero = BigDecimal::new("0.0")
    @one  = BigDecimal::new("1.0")
    @two  = BigDecimal::new("2.0")
    @ten  = BigDecimal::new("10.0")
    @eps  = BigDecimal::new("1.0e-1")
  end

  def zero;@zero;end

  def one ;@one ;end

  def two ;@two ;end

  def ten ;@ten ;end

  def eps ;@eps ;end

  def set_vars(t, rh, mrt, va)
    @t = BigDecimal.new(t.to_f.to_s)
    @rh = BigDecimal.new(rh.to_f.to_s)
    @mrt = BigDecimal.new(mrt.to_f.to_s)
    @va = BigDecimal.new(va.to_f.to_s)
  end

  def values(x) # <= defines functions solved
    f = []  
    f2 = RG::Comfort.utci(@t, x[0] / 100.0, @mrt, @va) - 26.0
    f <<= f2
  end
end

class Function3

  def initialize()
    @zero = BigDecimal::new("0.0")
    @one  = BigDecimal::new("1.0")
    @two  = BigDecimal::new("2.0")
    @ten  = BigDecimal::new("10.0")
    @eps  = BigDecimal::new("1.0e-2")
  end

  def zero;@zero;end

  def one ;@one ;end

  def two ;@two ;end

  def ten ;@ten ;end

  def eps ;@eps ;end

  def set_vars(t, rh, mrt, va)
    @t = BigDecimal.new(t.to_f.to_s)
    @rh = BigDecimal.new(rh.to_f.to_s)
    @mrt = BigDecimal.new(mrt.to_f.to_s)
    @va = BigDecimal.new(va.to_f.to_s)
  end

  def values(x) # <= defines functions solved  
    f = [RG::Comfort.utci(@t, @rh / 100.0, @mrt, x[0]) - 26.0]
    f
  end
end

class Function4

  def initialize()
    @zero = BigDecimal::new("0.0")
    @one  = BigDecimal::new("1.0")
    @two  = BigDecimal::new("2.0")
    @ten  = BigDecimal::new("10.0")
    @eps  = BigDecimal::new("1.0e-2")
  end

  def zero;@zero;end

  def one ;@one ;end

  def two ;@two ;end

  def ten ;@ten ;end

  def eps ;@eps ;end

  def set_vars(t, rh, mrt, va)
    @t = BigDecimal.new(t.to_f.to_s)
    @rh = BigDecimal.new(rh.to_f.to_s)
    @mrt = BigDecimal.new(mrt.to_f.to_s)
    @va = BigDecimal.new(va.to_f.to_s)
  end

  def values(x) # <= defines functions solved  
    f = [RG::Comfort.utci(@t, @rh / 100.0, x[0], @va) - 26.0]
    f
  end
end

def example
  rh_data = [0.2, 0.5, 0.8, 0.2, 0.5, 0.8]
  mrt_data = [28.0, 32.0, 36.0, 28.0, 32.0, 36.0]
  va_data = [1.0, 3.0, 5.0, 7.0, 9.0, 10.0]
  
  rh_data.zip(mrt_data, va_data).each do |rh, mrt, va| 
  
    f = BigDecimal::limit(100)
    f = Function.new
    f.set_vars(rh, mrt, va)
    x = [f.zero]      # Initial values
    n = nlsolve(f,x)
    x.map{|s| p s.to_f}
  end
end