module RG::Globals
	#Global variables
	$SIGMA = 5.67*10**(-8)
	$PERSON_EMISSIVITY_LONG_WAVE = 0.97 #For Kirchoff law this is also equal to the absorption coefficient of human body. Standard value.
	$PERSON_EMISSIVITY_SHORT_WAVE = 0.7 #For Kirchoff law this is also equal to the absorption coefficient of human body. Standard value.
	$SKIN_TEMPERATURE = 34.0
	$GROUND_PERSON_VIEW_FACTOR = 0.45
	$SKY_TEMPERATURE = 10.0
	$SUN_SOLID_ANGLE = 6.87e-5
	$BODY_AREA = 1.94 #m2
	$GROUND_REFLECTANCE = 0.20
	$SURROUNDINGS_EMISSIVITY = 0.8
	$GROUND_EMISSIVITY = 0.8
	
	$UNIT_METERS      = 4
	$UNIT_CENTIMETERS = 3
	$UNIT_MILLIMETERS = 2
	$UNIT_FEET        = 1
	$UNIT_INCHES      = 0
	$STL_ASCII  = 'ASCII'.freeze
	$STL_BINARY = 'Binary'.freeze
	
	$FOAM_RUN = '/home/osboxes/OpenFOAM/osboxes-2.3.1/run'
	$VMS = ['192.168.56.10', '192.168.56.11', '192.168.56.12', '192.168.56.13']
	$RADPATH = '/usr/local/radiance/bin/'
	$WEATHER_FOLDER = File.join(Dir.home, 'Library', 'Application Support', 'RadCalc' 'Weather')
	$SYSTEM_FILES = [".", "..", "Superceded", "Weather", "star_ccm_code", "cfd_files", "tmp", "settings", "CFD", "geometry"]
  
	
  $ENTITY_TYPES = [
    'fixed_surroundings', # These are immutable within the project
    'far_buildings',      # These also are immutable within the project
    'area_of_interest',   # This layer is dedicated to store the surface for the analysis
    'new_buildings',      # These are new buildings that can be added within a scenario
    'obstructions',       # These are volumetric obstructions that can be added within a scenario
    'baffles',            # These are surfaces such wind breakers and similar to be added within the scenario
    'shading',            # These are shading device to be added within the scenario 
    'refinement_volumes'  # Create refinement volumes for CFD
  ]
  
  $DISCIPLINES = ['radiation', 'cfd', 'radiance', 'comfort']
  
  
	$OPTIONS_STL = {
		'selection_only' => true,
		'export_units'   => 'Model Units',
		'stl_format'     => $STL_ASCII
	}
  
  $OPTIONS_OBJ = { :triangulated_faces   => false,
    :doublesided_faces    => true,
    :edges                => true,
    :author_attribution   => false,
    :texture_maps         => true,
    :selectionset_only    => true,
    :preserve_instancing  => false,
    :show_summary => false}

  $LOCAL_OS = Gem::Platform.local.os
  if $LOCAL_OS == 'mingw32'
    $ROOT = 'C:\CFD\\'
  else
    $ROOT = File.join(Dir.home, 'RadCalc')
    Dir.mkdir($ROOT) if !Dir.exists?($ROOT)
  end
  
end #globals

