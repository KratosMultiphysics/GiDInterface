
proc ::Dam::examples::ThermoMechaDam {args} {
    
    DrawDamGeometry
    AssignGroupsDam
    AssignDamMeshSizes
    TreeAssignationDam

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
}

proc Dam::examples::DrawDamGeometry {args} {
    
    Kratos::ResetModel
    GiD_Layers create Ground
    GiD_Layers create Dam
    GiD_Layers edit to_use Dam

    # Geometry creation
    ## Points ##
    set coordinates [list {0 0 0} {6 0 21} {57.50385 0 -31} {-35.8 0 -31} {6 0 31.1} {0 0 31.1} {-35.8 0 0} {57.50385 0 0} {22.8 0 0} ]
    set damPoints [list ]
    foreach point $coordinates {
        lassign $point x y z 
        lappend damPoints [GiD_Geometry create point append Dam $x $y $z]
    }
    
    ## Lines Ground ##
    set ground_lines [list ]
    set initial 4
    foreach point [list 7 1 9 8 3] {
        lappend ground_lines [GiD_Geometry create line append stline Ground $initial $point]
        set initial $point
    }
    lappend ground_lines [GiD_Geometry create line append stline Ground $initial 4]

    ## Lines Dam ##
    set dam_lines [list ]
    set initial 1
    foreach point [list 6 5 2 9] {
        lappend dam_lines [GiD_Geometry create line append stline Dam $initial $point]
        set initial $point
    }
    lappend dam_lines [GiD_Geometry create line append stline Dam $initial 1]

     ## Surface Ground ##
    GiD_Layers edit to_use Ground
    GiD_Process Mescape Geometry Create NurbsSurface {*}$ground_lines escape escape
    ## Surface Dam ##
    GiD_Layers edit to_use Dam
    GiD_Process Mescape Geometry Create NurbsSurface {*}$dam_lines escape escape

    GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,15,0.0 2 1 Mescape Mescape 


    GiD_Process 'Rotate Angle 270 0 
    GiD_Process 'Zoom Frame
        
}

proc Dam::examples::AssignGroupsDam {args} {
    
    # Create the groups
    GiD_Groups create Dam
    GiD_Groups edit color Dam "#26d1a8ff"
    GiD_EntitiesGroups assign Dam volumes 2
    
    GiD_Groups create Ground
    GiD_Groups edit color Ground "#e0210fff"
    GiD_EntitiesGroups assign Ground volumes 1
    
    GiD_Groups create Displacement
    GiD_Groups edit color Displacement "#3b3b3bff"
    GiD_EntitiesGroups assign Displacement surfaces {1 14 3 7 8}
      
    GiD_Groups create AmbientHeatFlux
    GiD_Groups edit color AmbientHeatFlux "#3b3b3bff"
    GiD_EntitiesGroups assign AmbientHeatFlux surfaces {4 9 10 11 12 6}
      
    GiD_Groups create Water
    GiD_Groups edit color Water "#3b3b3bff"
    GiD_EntitiesGroups assign Water surfaces {4 9}
      

}

proc Dam::examples::AssignDamMeshSizes {args} {
	
    set dam_mesh_size 2
    GiD_Process Mescape Meshing AssignSizes volumes $dam_mesh_size [GiD_EntitiesGroups get Dam volumes] escape escape
    GiD_Process Mescape Meshing AssignSizes volumes $dam_mesh_size [GiD_EntitiesGroups get Ground volumes] escape escape
    ##Kratos::BeforeMeshGeneration $dam_mesh_size
}

# Tree assign
proc Dam::examples::TreeAssignationDam {args} {

	set nd 3D
    set root [customlib::GetBaseRoot]

    # Set Type of problem strategy set
    spdAux::SetValueOnTreeItem v "Thermo-Mechanical" DamTypeofProblem

    # Dam Part
    set damParts [spdAux::getRoute "DamParts"]
    set damNode [customlib::AddConditionGroupOnXPath $damParts Dam]
    set props [list Element SmallDisplacementElement3D ConstitutiveLaw ThermalLinearElastic3DLaw Material "Concrete-Dam" DENSITY 2400 YOUNG_MODULUS 1.962e10 POISSON_RATIO 0.20 THERMAL_EXPANSION 1e-05]
    foreach {prop val} $props {
        set propnode [$damNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Dam $prop"
        }
    }
	
	#Soil Part
    set soilNode [customlib::AddConditionGroupOnXPath $damParts Ground]
    set props_soil [list Element SmallDisplacementElement3D ConstitutiveLaw ThermalLinearElastic3DLaw Material Soil DENSITY 3000 YOUNG_MODULUS 4.9e10 POISSON_RATIO 0.25 THERMAL_EXPANSION 1e-05]
    foreach {prop val} $props_soil {
        set propnode [$soilNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Dam $prop"
        }
    }
return
	# Dirichlet Conditions
	
		# Displacements
		set damDirichletConditions [spdAux::getRoute "DamNodalConditions"]
		set displacement "$damDirichletConditions/condition\[@n='DISPLACEMENT'\]"
		set displacemnetnode [customlib::AddConditionGroupOnXPath $displacement Displacement]
		
		# Surface Temperature 
		set initial "$damDirichletConditions/condition\[@n='INITIALTEMPERATURE'\]"
		set initialnode [customlib::AddConditionGroupOnXPath $initial Initial]
		set props_initial [list is_fixed 0 value 7.5 ]
		foreach {prop val} $props_initial {
			 set propnode [$initialnode selectNodes "./value\[@n = '$prop'\]"]
			 if {$propnode ne "" } {
				  $propnode setAttribute v $val
			 } else {
				W "Warning - Couldn't find property Initial $prop"
			}
		}

		# Bofang Temperature
		set bofang "$damDirichletConditions/condition\[@n='BOFANGTEMPERATURE'\]"
		set bofangnode [customlib::AddConditionGroupOnXPath $bofang Bofang]
		set props_bofang [list is_fixed 1 Gravity_Direction Y Reservoir_Bottom_Coordinate_in_Gravity_Direction 0.0 Surface_Temp 15.19 Bottom_Temp 9.35 Height_Dam 30.0 Temperature_Amplitude 6.51 Day_Ambient_Temp 201 Water_level 20.0 Month 7 ]
		foreach {prop val} $props_bofang {
			 set propnode [$bofangnode selectNodes "./value\[@n = '$prop'\]"]
			 if {$propnode ne "" } {
				  $propnode setAttribute v $val
			 } else {
				W "Warning - Couldn't find property Bofang $prop"
			}
		}
		
		# Uniform Temperature
		set uniform "$damDirichletConditions/condition\[@n='INITIALTEMPERATURE'\]"
		set uniformnode [customlib::AddConditionGroupOnXPath $uniform Uniform]
		set props_uniform [list is_fixed 1 value 10.0 ]
		foreach {prop val} $props_uniform {
			 set propnode [$uniformnode selectNodes "./value\[@n = '$prop'\]"]
			 if {$propnode ne "" } {
				  $propnode setAttribute v $val
			 } else {
				W "Warning - Couldn't find property Uniform $prop"
			}
		}
	
	
	# Thermal Load Conditions
	
		# Thermal Parameters 1
		set damThermalLoadConditions [spdAux::getRoute "DamThermalLoads"]
		set thermalparameter "$damThermalLoadConditions/condition\[@n='ThermalParameters2D'\]"
		set thermalparameternode1 [customlib::AddConditionGroupOnXPath $thermalparameter Thermal_Parameters_1]
		
		# Thermal Parameters 2
		set thermalparameternode2 [customlib::AddConditionGroupOnXPath $thermalparameter Thermal_Parameters_2]
		set props_thermal_2 [list ThermalDensity 3000 ]
		foreach {prop val} $props_thermal_2 {
			 set propnode [$thermalparameternode2 selectNodes "./value\[@n = '$prop'\]"]
			 if {$propnode ne "" } {
				  $propnode setAttribute v $val
			 } else {
				W "Warning - Couldn't find property Thermal_Parameters_2 $prop"
			}
		}
		
	# Load Conditions
   
		# Hydrostatic Load
        set damLoadConditions [spdAux::getRoute "DamLoads"]
		set hydro "$damLoadConditions/condition\[@n='HydroLinePressure2D'\]"
		set hydronode [customlib::AddConditionGroupOnXPath $hydro Hydrostatic]
		set props_hydro [list Modify 0 Gravity_Direction Y Reservoir_Bottom_Coordinate_in_Gravity_Direction 0.0 Spe_weight 10000 Water_level 20.0]
		foreach {prop val} $props_hydro {
			 set propnode [$hydronode selectNodes "./value\[@n = '$prop'\]"]
			 if {$propnode ne "" } {
				  $propnode setAttribute v $val
			 } else {
				W "Warning - Couldn't find property Hydrostatic $prop"
			}
		}
		
	# Solution
	spdAux::SetValueOnTreeItem v "Days" DamTimeScale

	# Results
    set results [list REACTION No TEMPERATURE Yes POSITIVE_FACE_PRESSURE Yes]]
    set nodal_path [spdAux::getRoute "NodalResults"]
    foreach {n v} $results {
        [$root selectNodes "$nodal_path/value\[@n = '$n'\]"] setAttribute v $v
    }
	

    spdAux::RequestRefresh


}

