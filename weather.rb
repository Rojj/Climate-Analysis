require 'time'
require 'r/utils.rb'
  
module RG::Weather

  #Provide basic functionalities to deal with EPW weather files
  #	require 'SU_Profiler/SU_Profiler.rb'

  
	class EPW
		attr_accessor :file
		attr_accessor :location
		attr_accessor :latitude
		attr_accessor :longitude
		attr_accessor :timezone
		attr_accessor :elevation
		attr_accessor :data
		attr_accessor :header


		def initialize(args)
		  #log = File.open('/Users/ruggiero/dev/weather.log', 'a')
      #RG::Utils.log_msg(log, "Generating Weather")
		  @file = args.fetch(:file, '/Users/ruggiero/Library/Application Support/RadCalc/Weather/Dubai_Intl_Airp_-hour.epw')
			@data = []
			@header = ["year", "month", "day", "hour", "minute", "source",
        "dry_bulb_temperature", "dew_point_temperature", "relative_humidity", "atmospheric_pressure",
        "rad_extraterrestrial_horizontal", "rad_extraterrestrial_direct_normal", "rad_horizontal_infrared_from_sky",
        "rad_global_horizontal", "rad_direct_normal", "rad_diffuse_horizontal",
        "ill_global_horizontal", "ill_direct_normal", "ill_diffuse_horizontal", "ill_zenith",
        "wind_direction", "wind_speed",
        "sky_cover_total", "sky_cover_opaque", "sky_cover_visibility", "sky_cover_ceiling_heigth",
        "present_weather_observation", "present_weather_codes", "precipitable_water", "aereosol_optical_depth",
        "snow_depth", "days_since_last_snowfall",
        "altitude", "azimuth"]
      
      
      load_weather_data(file)
      derived_weather_data({})
      #log.close
		end


		def load_weather_data(file)
			File.open(file) do |f|
				@file = file
				row = f.readline.chomp.split(',')
				@location = row[1]
				@latitude = row[6].to_f
				@longitude = row[7].to_f
				@timezone = row[8].to_f
				@elevation = row[9].to_f
				
				#set_shadow_info()
				
				(2..8).each{f.readline}
				until f.eof?
					row = f.readline.chomp.split(',')
					year, month, day, hour = row[0],row[1],row[2],row[3]
					time = Time.utc(year, month, day, hour) # Year, month, day_of_month, hour_of_day (0..23)
					doy = time.yday
					altitude, azimuth = RG::Utils::alt_az(doy * 1.0, hour.to_f, 0.0, 0.0, @timezone, @latitude, @longitude)
					row << altitude
					row << azimuth
					row.map!{|x| x.to_s.numeric? ? x.to_f : x}
					row = @header.zip(row).flatten
					@data << Hash[*row]
				end
			end
			return @data
		end
	 
    def set_shadow_info()
      @si["TZOffset"] = @timezone
      @si["Latitude"] = @latitude
      @si["Longitude"] = @longitude
      @si["City"] = @location   
    end
	
  	def derived_weather_data(args)
  	  log = args.fetch(:log, File.join(Dir.home, 'RadCalc'))
  		#RG::Utils.log_msg(log, 'Im in weather')
        
  		#Assign additional weather related parameters
      @data.each do |d|
        #d["wind_speed"] = d["wind_speed"].to_f
        #d["wind_direction"] = d["wind_direction"].to_f
        d["wind_rose"] = RG::Weather.wind_rose(d["wind_direction"])
        d["sun_vector"] = RG::Weather.sun_vector_from_time(d['year'], d['month'], d['day'], d['hour'], 0, 0, @timezone)
  			d["vp"] = d["relative_humidity"] / 100.0 * 6.105 * Math.exp(17.27 * d["dry_bulb_temperature"] / (237.7 + d["dry_bulb_temperature"])) #Vp in hPa => e = rh / 100 × 6.105 × exp ( 17.27 × Ta / ( 237.7 + Ta ) )
  			d["atmospheric_longwave"] = $SIGMA * (273.15 + d["dry_bulb_temperature"])**4 * (0.82 - 0.25 * 10**(-0.0945 * d["vp"])) * (1.0 + 0.21 * (d["sky_cover_total"] / 10.0)**2.5) #Atmospheric long wave radiation. This replaces the sky temperature and it is always present. This is for the whole skydomne. It will have to be scaled to the solid angle. This is divided by 10 because the data from epw files are based on 10
  			d["ground_temperature"] = d["dry_bulb_temperature"] #In first approximation we assume the ground surface temperature is equal to ambient temperature
  			d["ground_radiative_transfer_coefficient"] = 4.0 * $SIGMA * (273.15 + d["dry_bulb_temperature"])**3
  			d["ground_wind_speed"] = d["wind_speed"] * (0.5 / 10.0)**0.143 #Wind speed at 0.5m from the ground and assuming alpha = 0.11 according to power low
  			d["ground_convective_transfer_coefficient"] = [2.5, 4.0 + 4.0 * d["ground_wind_speed"]].max #Ground convective heat transfer coefficient. CIBSE Guide A
      
  	  end
      #RG::Utils.log_msg(log, 'Weather data calculated')
  	end
  end

  def self.su_time(year, month, day, hour, minute, second, timezone)
    # Returns the time in the format required by ShadowInfo['ShadowTime']
    if timezone >= 0
      timezone_code = '+' + Time.at(timezone * 3600).utc.strftime("%H:%M")
    else
      timezone_code = '-' + Time.at(timezone.abs * 3600).utc.strftime("%H:%M")
    end
    
    #puts timezone_code
    time = Time.new(year, month, day, hour, minute, second, timezone_code)
    #puts time
    return time.getlocal + timezone * 3600
  end
  
  def self.sun_vector_from_time(year, month, day, hour, minute, second, timezone) # time ignores the timezone
    
    # It returns the sun vector from time. Timezone offset needs to be specified
    si = Sketchup.active_model.shadow_info
    
    time_temp = si['ShadowTime']
    #puts 'before: ' + time_temp.to_s
        
    si['ShadowTime'] = su_time(year, month, day, hour, minute, second, timezone)
    #puts 'after: ' + @si['ShadowTime'].to_s
    #Sketchup.active_model.active_view.refresh
    #UI.refresh_inspectors()
    sun_vector = si['SunDirection'].to_a
    si['ShadowTime'] = time_temp
    return sun_vector
  end  
 
  def self.wind_rose(wd)
    wr = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    raise "Wind direction less than 0" if wd < 0
    raise "Wind direction greater than 360" if wd >360
    return "N" if wd < 22.5 || wd >= 337.5
    return "NE" if wd >= 22.5 && wd < 67.5
    return "E" if wd >= 67.5 && wd < 112.5
    return "SE" if wd >= 112.5 && wd < 157.5
    return "S" if wd >= 157.5 && wd < 202.5
    return "SW" if wd >= 202.5 && wd < 247.5
    return "W" if wd >= 247.5 && wd < 292.5
    return "NW" if wd >= 292.5 && wd < 337.5
  end
  
end #module Weather