
proc ::Dam::examples::ThermoMechaDam3D {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }
    DrawDamGeometry3D
    AssignGroupsDam3D
    AssignDamMeshSizes3D
    TreeAssignationDam3D
    
    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
}

proc Dam::examples::DrawDamGeometry3D {args} {
    
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

proc Dam::examples::AssignGroupsDam3D {args} {
    
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

proc Dam::examples::AssignDamMeshSizes3D {args} {
    
    set dam_mesh_size 2
    GiD_Process Mescape Meshing AssignSizes volumes $dam_mesh_size [GiD_EntitiesGroups get Dam volumes] escape escape
    GiD_Process Mescape Meshing AssignSizes volumes $dam_mesh_size [GiD_EntitiesGroups get Ground volumes] escape escape
    ##Kratos::BeforeMeshGeneration $dam_mesh_size
}

# Tree assign
proc Dam::examples::TreeAssignationDam3D {args} {
    
    set nd 3D
    set root [customlib::GetBaseRoot]
    
    # Set Type of problem strategy set
    spdAux::SetValueOnTreeItem v "Thermo-Mechanical" DamTypeofProblem
    
    # Dam Part
    set damParts [spdAux::getRoute "DamParts"]
    set damNode [customlib::AddConditionGroupOnXPath $damParts Dam]
    set props [list Element SmallDisplacementElement3D ConstitutiveLaw ThermalLinearElastic3DLaw Material "Concrete-Dam" DENSITY 2400 YOUNG_MODULUS 1.962e10 POISSON_RATIO 0.20 THERMAL_EXPANSION 1e-05]
    spdAux::SetValuesOnBaseNode $damNode $props
    
    #Soil Part
    set soilNode [customlib::AddConditionGroupOnXPath $damParts Ground]
    set props_soil [list Element SmallDisplacementElement3D ConstitutiveLaw ThermalLinearElastic3DLaw Material Soil DENSITY 3000 YOUNG_MODULUS 4.9e10 POISSON_RATIO 0.25 THERMAL_EXPANSION 1e-05]
    spdAux::SetValuesOnBaseNode $soilNode $props_soil
    
    
    # Dirichlet Conditions
    set damDirichletConditions [spdAux::getRoute "DamNodalConditions"]
    
    # Displacements
    set displacement "$damDirichletConditions/condition\[@n='DISPLACEMENT'\]"
    set displacemnetnode [customlib::AddConditionGroupOnXPath $displacement Displacement]
    
    # Surface Temperature 
    set temperature_base "$damDirichletConditions/condition\[@n='INITIALTEMPERATURE'\]"
    set dam_temperature [customlib::AddConditionGroupOnXPath $temperature_base Dam]
    set props_dam_temperature [list is_fixed false value 7.5 ]
    spdAux::SetValuesOnBaseNode $dam_temperature $props_dam_temperature
    
    # Constant Temperature
    set water_path "$damDirichletConditions/condition\[@n='CONSTANTRESERVOIRTEMPERATURE'\]"
    set water_node [customlib::AddConditionGroupOnXPath $water_path Water]
    set props_water [list is_fixed true Gravity_Direction Z Reservoir_Bottom_Coordinate_in_Gravity_Direction 0.0 Water_temp 8 Water_level 15]
    spdAux::SetValuesOnBaseNode $water_node $props_water
    
    # Load Conditions
    
    # Hydrostatic Load
    set damLoadConditions [spdAux::getRoute "DamLoads"]
    set hydro "$damLoadConditions/condition\[@n='HydroSurfacePressure3D'\]"
    set hydronode [customlib::AddConditionGroupOnXPath $hydro Water]
    set props_hydro [list Modify true Gravity_Direction Z Reservoir_Bottom_Coordinate_in_Gravity_Direction 0.0 Spe_weight 10000 Water_level 15.0]
    spdAux::SetValuesOnBaseNode $hydronode $props_hydro

    # Thermal Load Conditions

    # Thermal Load
    set damThermalLoadConditions [spdAux::getRoute "DamThermalLoads"]
    set thermal_load "$damThermalLoadConditions/condition\[@n='ThermalParameters3D'\]"
    set dam_thermal_node [customlib::AddConditionGroupOnXPath $thermal_load Dam]
    set props_dam_thermal [list ThermalDensity 2400 Conductivity 1.0 SpecificHeat 1000.0]
    spdAux::SetValuesOnBaseNode $dam_thermal_node $props_dam_thermal
    
    set ground_thermal_node [customlib::AddConditionGroupOnXPath $thermal_load Ground]
    set props_ground_thermal [list ThermalDensity 3000 Conductivity 1.0 SpecificHeat 1000.0]
    spdAux::SetValuesOnBaseNode $ground_thermal_node $props_ground_thermal

    
    # Ambient flux
    set ambient_flux_load "$damThermalLoadConditions/condition\[@n='TAmbientFlux3D'\]"
    set ambient_flux_node [customlib::AddConditionGroupOnXPath $ambient_flux_load AmbientHeatFlux]
    set props_ambient_flux [list h_0 3.5 ambient_temperature 10.0 ]
    spdAux::SetValuesOnBaseNode $ambient_flux_node $props_ambient_flux
    
    # Solution
    spdAux::SetValueOnTreeItem v "Days" DamTimeScale
    
    # Results
    set results [list REACTION No TEMPERATURE Yes POSITIVE_FACE_PRESSURE Yes]
    set nodal_path [spdAux::getRoute "NodalResults"]
    spdAux::SetValuesOnBasePath $nodal_path $results
    
    spdAux::RequestRefresh
    
    
}

