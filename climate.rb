require 'r/comfort.rb'
require 'r/mesh.rb'
require 'r/weather.rb'
require 'RG/climate/solver.rb'
weather = RG::Weather::EPW.new(:file => '/Users/ruggiero/Library/Application Support/RadCalc/Weather/MANIhour.epw')
#weather = RG::Weather::EPW.new({})
temp = weather.data.map{|d| d["dry_bulb_temperature"]}
hum = weather.data.map{|d| d["relative_humidity"]}
wind = weather.data.map{|d| d["wind_speed"]}
rad = [30.0]

comfort = []
out_comfort = []
coords = []
out_coords = []


rad.each do |mrt|
  temp.zip(hum, wind).each do |t, rh, va|
  #puts "Temperature: #{t} and humidity #{rh}"
    c = RG::Comfort.utci(t.to_f, rh / 100.0, t.to_f, va)
    #puts "and comfort is: #{c}"
    if (c <= 26.0 && c >= 9.0)
      comfort << c
      coords << [t.to_f, rh.to_f, va]
    else
      out_comfort << c
      out_coords << [t.to_f, rh.to_f, va]
    end
  end
  
  # Sketchup
  # mod = Sketchup.active_model
  # ent = mod.entities
  # coords.each do |c|
    # ent.add_cpoint(c)
  # end
  # out_coords.each do |c|
    # ent.add_cpoint(c)
  # end
  
   
  
  # Output
  # File.open('/Users/ruggiero/dev/comfort_' + mrt.to_i.to_s + '.csv', 'w') do |f|
    # f.puts 'temperature, humidity, wind, utci'
    # coords.zip(comfort).each do |coord, c|
      # f.puts coord.join(",") + ',' + c.to_s 
    # end
  # end
# 
  # File.open('/Users/ruggiero/dev/discomfort_' + mrt.to_i.to_s + '.csv', 'w') do |f|
    # f.puts 'temperature, humidity, wind, utci'
    # out_coords.zip(out_comfort).each do |coord, c|
      # f.puts coord.join(",")  + ',' + c.to_s 
    # end
  # end

end

hot_discomfort = out_comfort.zip(out_coords).select{|d| d[0] >26}[0..10]
puts "Calculating #{hot_discomfort.size.to_s} values"

t_data = hot_discomfort.map{|x| x[1][0]}
rh_data = hot_discomfort.map{|x| x[1][1]}
va_data = hot_discomfort.map{|x| x[1][2]}

st = Time.now
t_count = 0
t_data.zip(rh_data, va_data).each do |t, rh, va| 

  f = BigDecimal::limit(100)
  f = Function.new
  f.set_vars(t, rh, t, va)
  x = [f.zero]      # Initial values
  n = nlsolve(f,x)
  sol = x[0]
  if (t - sol) > 0
    #p "From #{t} down to #{sol.to_f}. dT = #{(t - sol).to_f.to_s}"
    t_count +=1
  else
    p "WARNING! Solution greater than original temperature"
    puts "For (t, rh, t, va): #{t.to_s}, #{rh.to_s}, #{t.to_s} and #{va.to_s}" 
  end
  
end
puts "Calculated in #{(Time.now - st).to_s} and found #{t_count.to_s} possible values"


# Humidity
puts
st = Time.now
rh_count = 0
t_data.zip(rh_data, va_data).each do |t, rh, va| 

  f = BigDecimal::limit(100)
  f = Function2.new
  f.set_vars(t, rh, t, va)
  begin 
    x = [f.zero]      # Initial values
    n = nlsolve(f,x)
    sol = x[0]
    if sol >= 20.0
      #p "From #{rh} down to #{sol.to_f}. dRH = #{(rh - sol).to_f.to_s}"
      rh_count +=1
    else
      p "WARNING! Humidity below 20%"
      puts "For (t, rh, t, va): #{t.to_s}, #{rh.to_s}, #{t.to_s} and #{va.to_s}"
    end
  rescue
    puts "Cannot find solution for humidity"
    puts "For (t, rh, t, va): #{t.to_s}, #{rh.to_s}, #{t.to_s} and #{va.to_s}"
  end
end

puts "Calculated in #{(Time.now - st).to_s} and found #{rh_count.to_s} possible values"

# Air speed
puts
st = Time.now
va_count = 0
t_data.zip(rh_data, va_data).each do |t, rh, va| 

  f3 = BigDecimal::limit(100)
  f3 = Function3.new
  f3.set_vars(t, rh, t, va)
  #puts "Solving for (t, rh, t, va): #{t.to_s}, #{rh.to_s}, #{t.to_s} and #{va.to_s}"
  begin 
    
    x = [BigDecimal::new((va * 1.0).to_s)]
    n = nlsolve(f3,x)
    sol = x[0]
    if (sol > va) && sol <= 15.0
      #p "From #{va} up to #{sol.to_f}. dVA = #{(sol - va).to_f.to_s}"
      va_count += 1
    else
      p "WARNING! Wind above 15 m/s"
      puts "For (t, rh, t, va): #{t.to_s}, #{rh.to_s}, #{t.to_s} and #{va.to_s}"
    end
  rescue
    puts "Cannot find solution for wind"
    puts "For (t, rh, t, va): #{t.to_s}, #{rh.to_s}, #{t.to_s} and #{va.to_s}"
  end
end
puts "Calculated in #{(Time.now - st).to_s} and found #{va_count.to_s} possible values"

# Radiation
puts
st = Time.now
mrt_count = 0
t_data.zip(rh_data, va_data).each do |t, rh, va| 

  f4 = BigDecimal::limit(100)
  f4 = Function4.new
  f4.set_vars(t, rh, t, va)
  #puts "Solving for (t, rh, t, va): #{t.to_s}, #{rh.to_s}, #{t.to_s} and #{va.to_s}"
  begin 
    
    x = [BigDecimal.new(t.to_f.to_s)]      # Initial values
    n = nlsolve(f4,x)
    sol = x[0]
    if (sol > 15.0)
      #p "From #{va} up to #{sol.to_f}. dVA = #{(sol - va).to_f.to_s}"
      mrt_count += 1
    else
      p "WARNING! MRT below 15 "
      puts "For (t, rh, t, va): #{t.to_s}, #{rh.to_s}, #{t.to_s} and #{va.to_s}"
    end
  rescue
    puts "Cannot find solution for MRT"
    puts "For (t, rh, t, va): #{t.to_s}, #{rh.to_s}, #{t.to_s} and #{va.to_s}"
  end
end
puts "Calculated in #{(Time.now - st).to_s} and found #{mrt_count.to_s} possible values"




puts "\nSUMMARY"
puts "Temperature: #{(t_count.to_f / hot_discomfort.size.to_f * 100.0).round(0)}%"
puts "MRT: #{(mrt_count.to_f / hot_discomfort.size.to_f * 100.0).round(0)}%"
puts "Humidity: #{(rh_count.to_f / hot_discomfort.size.to_f * 100.0).round(0)}%"
puts "Wind: #{(va_count.to_f / hot_discomfort.size.to_f * 100.0).round(0)}%"


