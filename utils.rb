require 'Sketchup'
require 'date'
require 'r/globals.rb' #Constants and global variables

class String
  def numeric?
    Float(self) != nil rescue false
  end
end

module RG::Utils
	
	#	require 'SU_Profiler/SU_Profiler.rb'
	def self.log_msg(file, string)
    message = Time.now.to_s + ': ' + string
    (file == nil) ? (puts message) : (file.puts message)
    file.flush
  end
  
  def self.obj_to_json(obj)
    hash = {}
    obj.instance_variables.each {|var| hash[var.to_s.delete("@")] = obj.instance_variable_get(var) }
    return hash
  end
  
  def self.marshal_load(filename)
    file = File.open(filename,'rb')
    object = Marshal.load(file)
    file.close
    return object
  end


  def self.marshal_dump(filename, object)
    file = File.open(filename,"wb")
    file.write(Marshal.dump(object))
    file.close
  end

	
  def self.load_json(filename)
		json_file = File.read(filename)
		return JSON.parse(json_file)
  end

  
  def self.write_json(object, filename)
    file = File.open( filename , "w")
    file.write(JSON.dump(object))
    file.close
  end

  
	def self.alt_az(day_of_year, hour, min, sec, tz, lat, long) #lat and long in degrees
		gamma = 360.0 / 365.0 * (day_of_year - 1.0)
		et = 2.2918 * (0.0075 + 0.1868 * Math.cos(gamma.degrees) - 3.2077 * Math.sin(gamma.degrees) - 1.4615 * Math.cos(2.0 * gamma.degrees) - 4.0849 * Math.sin(2.0 * gamma.degrees))
		lsm = 15.0 * tz
		ast = hour + et / 60.0 + (long - lsm) / 15.0
		delta = 23.45 * Math.sin((360.0 * (day_of_year + 284.0) / 365.0).degrees)
		h = 15.0 * (ast - 12.0)
		altitude = [0.0, Math.asin(Math.cos(lat.degrees) * Math.cos(delta.degrees) * Math.cos(h.degrees) + Math.sin(lat.degrees) * Math.sin(delta.degrees))].max
		sin_phi =  Math.sin(h.degrees) * Math.cos(delta.degrees) / Math.cos(altitude.degrees)
		cos_phi = (Math.cos(h.degrees) * Math.cos(delta.degrees) * Math.sin(lat.degrees) - Math.sin(delta.degrees) * Math.cos(lat.degrees)) / Math.cos(altitude.degrees)
		azimuth = Math.atan2(sin_phi, cos_phi) 
		azimuth = (altitude > 0.0) ? (Math::PI + azimuth) : 0.0
		return altitude.radians, azimuth.radians #Both in degrees. Azimuth from North
	end
	
  # Returns the definition for a +Group+, +ComponentInstance+ or +Image+
	#
	# @param [:definition, Sketchup::Group, Sketchup::Image] instance
	#
	# @return [Sketchup::ComponentDefinition,Mixed]


  def self.definition(instance)
		if instance.respond_to?(:definition)
			return instance.definition
    elsif instance.is_a?(Sketchup::Group)
			# (i) group.entities.parent should return the definition of a group.
			# But because of a SketchUp bug we must verify that group.entities.parent
			# returns the correct definition. If the returned definition doesn't
			# include our group instance then we must search through all the
			# definitions to locate it.
			if instance.entities.parent.instances.include?(instance)
				return instance.entities.parent
      else
				Sketchup.active_model.definitions.each { |definition|
					return definition if definition.instances.include?(instance)
				}
			end
    elsif instance.is_a?(Sketchup::Image)
			Sketchup.active_model.definitions.each { |definition|
				if definition.image? && definition.instances.include?(instance)
					return definition
				end
			}
		end
    return nil # Given entity was not an instance of an definition.
	end


	def self.draw_refinement_boundaries(cfd_settings)
		puts self
    mats=Sketchup.active_model.materials
		nmat = mats.add('bounds_color')
		nmat.color = [0,191,255]
		nmat.alpha = 0.15 
		
		refinement = Sketchup.active_model.entities.add_group
		point = refinement.entities.add_cpoint(Geom::Point3d.new([0,0,0]))
    refinement.entities.add_group self.cylinder_at(cfd_settings["x_center"], cfd_settings["y_center"], cfd_settings["z_center"], 20.0, cfd_settings["radius_1H"])
		puts refinement
    refinement.entities.add_group self.cylinder_at(cfd_settings["x_center"], cfd_settings["y_center"], cfd_settings["z_center"], 20.0, cfd_settings["radius_3H"])
    refinement.entities.add_group self.cylinder_at(cfd_settings["x_center"], cfd_settings["y_center"], cfd_settings["z_center"], 20.0, cfd_settings["radius_5H"])
		
    v1 = Geom::Point3d.new((cfd_settings["x_center"] + cfd_settings["x_domain_left"]).m, (cfd_settings["y_center"] + cfd_settings["y_domain_bottom"]).m, 0.0.m)
		v2 = Geom::Point3d.new((cfd_settings["x_center"] + cfd_settings["x_domain_right"]).m, (cfd_settings["y_center"] + cfd_settings["y_domain_bottom"]).m, 0.0.m)
		v3 = Geom::Point3d.new((cfd_settings["x_center"] + cfd_settings["x_domain_right"]).m, (cfd_settings["y_center"] + cfd_settings["y_domain_top"]).m, 0.0.m)
		v4 = Geom::Point3d.new((cfd_settings["x_center"] + cfd_settings["x_domain_left"]).m, (cfd_settings["y_center"] + cfd_settings["y_domain_top"]).m, 0.0.m)
		domain = Sketchup.active_model.entities.add_group
		base = domain.entities.add_face(v1, v2, v3, v4)
		base.material = 'bounds_color'
		base.back_material = 'bounds_color'
		base.reverse!
		base.pushpull cfd_settings["z_domain_up"].m # -h or base.reverse! for positive z
		refinement.entities.erase_entities point
	end


	def self.cylinder_at(x, y, z, h, r)
    puts Time.now.to_s
    n=24 # Number of segments for the cylinder
		cylinder = Sketchup.active_model.entities.add_group
    circle_base = cylinder.entities.add_circle(Geom::Point3d.new(x.m ,y.m ,z.m), Z_AXIS, r.m, n)
		base = cylinder.entities.add_face(circle_base)
		base.material = 'bounds_color'
		base.back_material = 'bounds_color'
		base.pushpull h.m # -h or base.reverse! for positive z
    return cylinder
	end 

  def self.spher_to_cart(theta, phi)
    x = Math.sin(theta)*Math.cos(phi)
    y = Math.sin(theta)*Math.sin(phi)
    z = Math.cos(theta)
    return [x.round(12), y.round(12), z.round(12)]
  end
  
   def self.color_lookup(s, min, max)
     
    color_table = [[76, 108, 168], [96, 124, 171], [159, 189, 239], [186, 208, 219], [224, 229, 145], \
                   [249, 234, 60], [247, 201, 53], [239, 146, 15], [233, 113, 0], [233, 70, 0], [234, 37, 0]]
    
    if s < min
      return color_table[0]
    end
    if s >= max
      return color_table[color_table.size - 1]
    end
    
    return color_table[ (color_table.size * (s - min) / (max-min)).floor ]
         
  end   
  
  def self.ts_to_hoy(ts)
    return (ts.yday.to_i - 1) * 24 + ts.hour.to_i
  end
  

	def self.create_area_folders(root, project, area, scenario)
    #Create folders
    path_area = File.join($ROOT, project, area)
    if !Dir.exists?(path_area)
      Dir.mkdir( File.join($ROOT, project, area) )
      Dir.mkdir( File.join($ROOT, project, area, 'geometry') )
      Dir.mkdir( File.join($ROOT, project, area, 'settings') )
    end
    Dir.mkdir( File.join($ROOT, project, area, scenario ) )
    Dir.mkdir( File.join($ROOT, project, area, scenario, 'geometry') )
    Dir.mkdir( File.join($ROOT, project, area, scenario, 'settings') )

    disciplines = ['radiation', 'cfd', 'radiance', 'comfort']
    disciplines.each do |d|
      Dir.mkdir( File.join($ROOT, project, area, scenario, d) )
      Dir.mkdir( File.join($ROOT, project, area, scenario, d, 'settings') )
      Dir.mkdir( File.join($ROOT, project, area, scenario, d, 'temp') )
      Dir.mkdir( File.join($ROOT, project, area, scenario, d, 'outputs') )      
      #The discipline should create specific directories
    end
  end

	
	#This function reads a epw weather file and converts into a dictionary
	def self.epw_to_dict(file)
		File.open(file) do|f|
			columns = ["year", "month", "day", "hour", "minute", "source",
        "dry_bulb_temperature", "dew_point_temperature", "relative_humidity", "atmospheric_pressure",
        "rad_extraterrestrial_horizontal", "rad_extraterrestrial_direct_normal", "rad_horizontal_infrared_from_sky",
        "rad_global_horizontal", "rad_direct_normal", "rad_diffuse_horizontal",
        "ill_global_horizontal", "ill_direct_normal", "ill_diffuse_horizontal", "ill_zenith",
        "wind_direction", "wind_speed",
        "sky_cover_total", "sky_cover_opaque", "sky_cover_visibility", "sky_cover_ceiling_heigth",
        "present_weather_observation", "present_weather_codes", "precipitable_water", "aereosol_optical_depth",
        "snow_depth", "days_since_last_snowfall"]
			(1..8).each{f.readline}
			table = []
			until f.eof?
				row = f.readline.chomp.split(',')
				row = columns.zip(row).flatten
				table << Hash[*row]
			end
			#table = table.reduce({}) {|h,pairs| pairs.each {|k,v| (h[k] ||= []) << v}; h}
			return table
		end
	end

	#This function reads an STL file and returns a mesh
	def self.stl_ascii_import(filename)

		polygons = []
		triangle = []
		num_vertices = 0
		# Ensure to open the file in with no encoding.
		filemode = 'r'
		if RUBY_VERSION.to_f > 1.8
		  filemode << ':ASCII-8BIT'
		end
		File.open(filename, filemode) { |file|
      file.each_line { |line|
        line.chomp!
        if line[/vertex/]
          num_vertices += 1
          entity_type, *point = line.split
          point.map! { |value| value.to_f.m }
          triangle << point
          if num_vertices == 3
            polygons.push(triangle.dup)
            triangle = []
            num_vertices = 0
          end
        end
      }
    }
		mesh = Geom::PolygonMesh.new(3 * polygons.length, polygons.length)
		polygons.each{ |tri| mesh.add_polygon(tri) }
		# entities = Sketchup.active_model.entities
		# if entities.length > 0
    # group = entities.add_group
    # entities = group.entities
		# end
		# entities.fill_from_mesh(mesh, false, MESH_NO_SOFTEN_OR_SMOOTH)
		# entities
		return mesh
	end
	#mesh_from_file = stl_ascii_import(r'J:\Transfer\DetailMeshed.csv')

	def self.stl_ascii_import(filename)
    #Use this part if you want to import an stl file with the cell vertices
    # mesh_from_file = stl_ascii_import('J:\Transfer\HotelDetail.stl')
    #Let's first export a tringulation for plotting
    # list_of_points = []
    # mesh_from_file.points.each do |pt|
		# list_of_points << pt
    # end
    # list_of_triangles = [] #each element is an array of three indeces (in general this is a poligon
    # mesh_from_file.polygons.each do |pl|
		# list_of_triangles << pl
	end

	#This function converts between polar coordinates and Degrees-from-North 
	def self.PolarToNorth(angle,units)
		if units == 'radians'
			if ((Math::PI / 2.0) - angle)>=0.0
				phi = (Math::PI / 2.0) - angle
			else
				phi = (Math::PI / 2.0) -angle + 2.0 * Math::PI
			end
		else
			if (90.0-angle)>=0.0
				phi = 90.0-angle
			else
				phi = 90.0-angle+ 360.0
			end
		end
		return phi
	end

	#This function calculates the angle betwen two vectors when represented by arrays. Too slow!!!
	def self.angle_between_vectors(v1,v2)
		# dot = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
		# norm1 = Math.sqrt(v1.x ** 2 + v1.y ** 2 + v1.z ** 2)
		# norm2 = Math.sqrt(v2.x ** 2 + v2.y ** 2 + v2.z ** 2)
		# return Math.acos(dot / (norm1 * norm2))
		v1_v = Geom::Vector3d.new(v1)	
		v2_v = Geom::Vector3d.new(v2)
		return v1_v.angle_between(v2_v)
  end
	
	def self.flag_surfaces()
    mod = Sketchup.active_model
    ent = mod.entities
    sel = mod.selection
    
    # The surface of analysis have to be included in groups
    # Areas SHOULD NOT intersect groups on the boundaries
    if sel == []
      UI.messagebox("Please select at least one surface!")
      exit
    end
    
    sel.each do |sg|
      sg.attribute_dictionary('RadCalc_Entities', true)['flagged_for_analysis'] = true
    end
  end
	
	def self.generate_aoi()
	  mod = Sketchup.active_model
	  ent = mod.entities
	  
	  # This will genarate a circular area around the model at 1.75 m from ground. It assumes that buildings are at z = 0
	  bounds = mod.bounds
	  # Center of the domain
	  xc = bounds.center.x
	  yc = bounds.center.y
	  zc = 1.75.m
	  
	  domain_radius = Math::sqrt((bounds.max.x - bounds.min.x) ** 2 + (bounds.max.y - bounds.min.y) ** 2) / 2.0
	  
	  aoi_radius = 1.1 * domain_radius
	  aoi = Sketchup.active_model.entities.add_group
    circle = aoi.entities.add_circle(Geom::Point3d.new(xc ,yc ,zc), Z_AXIS.reverse, aoi_radius)
    aoi.entities.add_face(circle)
    
    aoi.attribute_dictionary('RadCalc_Entities', true)['EntityType'] = 'area_of_interest'
	  aoi.attribute_dictionary('RadCalc_Entities', true)['flagged_for_analysis'] = true
	  return aoi 
	end
	
	def self.flag_irradiated_surfaces()
	  
    mod = Sketchup.active_model 
    ent = mod.entities # All entities in model
    sel = mod.selection

    # The irradiated surfaces have to be included in groups
    surface_groups =  sel.grep(Sketchup::Group)
    
    if surface_groups == []
      UI.messagebox("Please select at least one surface!")
      exit
    end
 
    prompts = ['MeshDelta']
    defaults = [1.0]
    list = ['']
    input = UI.inputbox(prompts, defaults, list, 'Select mesh refinement for selected surfaces')

    dict_name = "RadCalc_IrradiatedSurface"

    surface_groups.each do |sg|
      sg.attribute_dictionary(dict_name,true)
      sg.set_attribute dict_name, 'irradiated', true
      sg.set_attribute dict_name, 'delta', input[0] 
      sg.entities.grep(Sketchup::Face).each do |f|
        f.attribute_dictionary(dict_name,true)
        f.set_attribute dict_name, 'irradiated', true
        f.set_attribute dict_name, 'delta', input[0]  
      end
    end  

    mod.save
 
	  
	end
	
  def self.cut_surfaces(tools, surface_group) #log
    #surfaces.make_unique
    puts 'BEFORE INTERSECTION'
    puts 'All entities in group'
    puts surface_group.entities.each{|e| p e}
    #surface.entities.select{|e| e.is_a?(Sketchup::Face)}.each{|e| p e.to_s}
    orig_surfaces = surface_group.entities.select{|s| s.is_a?(Sketchup::Face)}
    puts "All surfaces in group\n" + orig_surfaces.to_s

    tools.each do |t|
      arrays  = t.entities.intersect_with false, t.transformation, surface_group.entities, surface_group.transformation, \
      false, surface_group
    end
    puts 'AFTER INTERSECTION'
    puts 'All surfaces in group'
    surface_group.entities.grep(Sketchup::Face).each{|e| p e.to_s}

    del = surface_group.entities.grep(Sketchup::Face).select{|e| !orig_surfaces.include?(e)}
    puts 'Surfaces to be deleted'
    del.each{|e| p e}
    del.each do |e|
      surface_group.entities.erase_entities(e)
    end
    return true
  end

  # Calculates a series of timesteps given start time and end time
  # Params:
  # - start_time: start local time
  # - end_time: end local time
  def self.extract_timesteps(start_time, end_time, day_start, day_end, one_day_per_month)
    time_interval = (end_time - start_time) / 3600 #Total number of hours from starting day to lst day
    timesteps = [] #This the the list of times to analyze
    for i in 0...time_interval
      time = start_time + i * 60 * 60 #Original time to be used for Ruby only calls
      if one_day_per_month
        if time.day == 15
          day = ((time.hour >= day_start) && (time.hour < day_end))
          timesteps << time if day
        end
      else
        day = ((time.hour >= day_start) && (time.hour < day_end))
        timesteps << time if day
      end
    end
    puts timesteps
    return timesteps
  end
  
  def self.open_paraview_file(filename)
    cmd = '/Applications/paraview.app/Contents/MacOS/paraview --data="' + filename + '"'
    puts cmd
    pid = spawn cmd
  end
  
  def self.vtk_png(folder)
    # Converts all 
  end
	
end #RG::Utils	