namespace eval ::Dam::examples::ThermoMechaDam2D {
    namespace path ::Dam::examples
    Kratos::AddNamespace [namespace current]

}

proc ::Dam::examples::ThermoMechaDam2D::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }

    DrawGeometry
    AssignGroups
    AssignMeshSizes
    TreeAssignation

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
}

proc ::Dam::examples::ThermoMechaDam2D::DrawGeometry {args} {

    Kratos::ResetModel

    # Dam #
    GiD_Layers create Dam
    GiD_Layers edit to_use Dam

    # Geometry creation
    ## Points ##
    set dam_coordinates [list {0 0 0} {10 0 0} {3 30 0} {0 30 0} ]
    set damPoints [list ]
    foreach point $dam_coordinates {
        lassign $point x y z
        lappend damPoints [GiD_Geometry create point append Dam $x $y $z]
    }

    ## Lines ##
    set damLines [list ]
    set initial [lindex $damPoints 0]
    foreach point [lrange $damPoints 1 end] {
        lappend damLines [GiD_Geometry create line append stline Dam $initial $point]
        set initial $point
    }
    lappend damLines [GiD_Geometry create line append stline Dam $initial [lindex $damPoints 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$damLines escape escape


    # Ground #
    GiD_Layers create Ground
    GiD_Layers edit color Ground "#999900ff"
    GiD_Layers edit to_use Ground

    # Geometry creation
    ## Points ##
    set ground_coordinates [list {-5 0 0} {-5 -5 0} {15 -5 0} {15 0 0} ]
    set groundPoints [list ]
    foreach point $ground_coordinates {
        lassign $point x y z
        lappend groundPoints [GiD_Geometry create point append Ground $x $y $z]
    }

    ## Lines ##
    set groundLines [list ]
    set initial [lindex $damPoints 0]
    foreach point [lrange $groundPoints 0 end] {
        lappend groundLines [GiD_Geometry create line append stline Ground $initial $point]
        set initial $point
    }
    lappend groundLines [GiD_Geometry create line append stline Ground $initial [lindex $damPoints 1]]

    lappend groundLines 1

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$groundLines escape escape

    # Swap normals of hydrostatic pressure and heat flux surfaces to point outside the volume
    GiD_Process Mescape Utilities SwapNormals Lines Select 2 escape escape
    GiD_Process Mescape Utilities SwapNormals Lines Select 3 escape escape
    GiD_Process Mescape Utilities SwapNormals Lines Select 4 escape escape
    GiD_Process Mescape Utilities SwapNormals Lines Select 5 escape escape
    GiD_Process Mescape Utilities SwapNormals Lines Select 9 escape escape

    GiD_Process 'Zoom Frame

}

proc ::Dam::examples::ThermoMechaDam2D::AssignGroups {args} {

    # Create the groups
    GiD_Groups create Dam
    GiD_Groups edit color Dam "#26d1a8ff"
    GiD_EntitiesGroups assign Dam surfaces 1

    GiD_Groups create Ground
    GiD_Groups edit color Ground "#e0210fff"
    GiD_EntitiesGroups assign Ground surfaces 2

    GiD_Groups create Displacement
    GiD_Groups edit color Displacement "#3b3b3bff"
    GiD_EntitiesGroups assign Displacement lines 7

    GiD_Groups create UniformTemperature
    GiD_Groups edit color UniformTemperature "#3b3b3bff"
    GiD_EntitiesGroups assign UniformTemperature lines {2 3 4 5 9}

    GiD_Groups create Water
    GiD_Groups edit color Water "#26d1a8fe"
    GiD_EntitiesGroups assign Water lines {4 5}

}

proc ::Dam::examples::ThermoMechaDam2D::AssignMeshSizes {args} {

    set dam_mesh_size 0.25
    GiD_Process Mescape Meshing AssignSizes Surfaces $dam_mesh_size 1:end escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $dam_mesh_size 1:end escape escape
    ##Kratos::BeforeMeshGeneration $dam_mesh_size
}

# Tree assign
proc ::Dam::examples::ThermoMechaDam2D::TreeAssignation {args} {

    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    # Set Type of problem strategy set
    spdAux::SetValueOnTreeItem v "Thermo-Mechanical" DamTypeofProblem

    # Dam Part
    set damParts [spdAux::getRoute "DamParts"]
    set damNode [customlib::AddConditionGroupOnXPath $damParts Dam]
    set props [list Element SmallDisplacementElement2D ConstitutiveLaw ThermalLinearElastic2DPlaneStrain Material "Concrete-Dam" DENSITY 2400 YOUNG_MODULUS 1.962e10 POISSON_RATIO 0.20 THERMAL_EXPANSION 1e-05]
    spdAux::SetValuesOnBaseNode $damNode $props

    # Ground Part
    set groundNode [customlib::AddConditionGroupOnXPath $damParts Ground]
    set props_ground [list Element SmallDisplacementElement2D ConstitutiveLaw ThermalLinearElastic2DPlaneStrain Material Ground DENSITY 3000 YOUNG_MODULUS 4.9e10 POISSON_RATIO 0.25 THERMAL_EXPANSION 1e-05]
    spdAux::SetValuesOnBaseNode $groundNode $props_ground


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

        set ground_temperature [customlib::AddConditionGroupOnXPath $temperature_base Ground]
        set props_ground_temperature [list is_fixed false value 7.5 ]
        spdAux::SetValuesOnBaseNode $ground_temperature $props_ground_temperature

        # Bofang Temperature
        set bofang_temperature "$damDirichletConditions/condition\[@n='BOFANGTEMPERATURE'\]"
        set bofang_temperature_node [customlib::AddConditionGroupOnXPath $bofang_temperature Water]
        set props_bofang_temperature [list is_fixed 1 Gravity_Direction Y Reservoir_Bottom_Coordinate_in_Gravity_Direction 0.0 Surface_Temp 15.19 Bottom_Temp 9.35 Height_Dam 30.0 Temperature_Amplitude 6.51 Day_Max_Temp 201 Water_level 20.0 Month 7 ]
        spdAux::SetValuesOnBaseNode $bofang_temperature_node $props_bofang_temperature

        # Uniform Temperature
        set uniform_temperature "$damDirichletConditions/condition\[@n='INITIALTEMPERATURE'\]"
        set uniform_temperature_node [customlib::AddConditionGroupOnXPath $uniform_temperature UniformTemperature]
        set props_uniform_temperature [list is_fixed true value 10.0 ]
        spdAux::SetValuesOnBaseNode $uniform_temperature_node $props_uniform_temperature


    # Load Conditions

        # Hydrostatic Load
        set damLoadConditions [spdAux::getRoute "DamLoads"]
        set hydrostatic_load "$damLoadConditions/condition\[@n='HydroLinePressure2D'\]"
        set hydrostatic_load_node [customlib::AddConditionGroupOnXPath $hydrostatic_load Water]
        set props_hydrostatic_load [list Modify 0 Gravity_Direction Y Reservoir_Bottom_Coordinate_in_Gravity_Direction 0.0 Spe_weight 10000 Water_level 20.0]
        spdAux::SetValuesOnBaseNode $hydrostatic_load_node $props_hydrostatic_load

    # Thermal Load Conditions

        # Thermal Parameters Dam
	set damThermalLoadConditions [spdAux::getRoute "DamThermalLoads"]
        set thermal_parameters "$damThermalLoadConditions/condition\[@n='ThermalParameters2D'\]"
        set dam_thermal_node [customlib::AddConditionGroupOnXPath $thermal_parameters Dam]
        set props_dam_thermal [list ThermalDensity 2400 Conductivity 1.0 SpecificHeat 1000.0]
        spdAux::SetValuesOnBaseNode $dam_thermal_node $props_dam_thermal

        # Thermal Parameters Ground
        set ground_thermal_node [customlib::AddConditionGroupOnXPath $thermal_parameters Ground]
        set props_ground_thermal [list ThermalDensity 3000 Conductivity 1.0 SpecificHeat 1000.0]
        spdAux::SetValuesOnBaseNode $ground_thermal_node $props_ground_thermal


    # Reference temperature

        # Reference temperature Dam
        set dam_reference_temperature "$damThermalLoadConditions/condition\[@n='NodalReferenceTemperature2D'\]"
        set dam_reference_temperature_node [customlib::AddConditionGroupOnXPath $dam_reference_temperature Dam]
        set props_dam_reference_temperature [list initial_value 7.5 ]
        spdAux::SetValuesOnBaseNode $dam_reference_temperature_node $props_dam_reference_temperature

        # Reference temperature Ground
        set ground_reference_temperature "$damThermalLoadConditions/condition\[@n='NodalReferenceTemperature2D'\]"
        set ground_reference_temperature_node [customlib::AddConditionGroupOnXPath $ground_reference_temperature Ground]
        set props_ground_reference_temperature [list initial_value 7.5 ]
        spdAux::SetValuesOnBaseNode $ground_reference_temperature_node $props_ground_reference_temperature


	# Solution
	spdAux::SetValueOnTreeItem v "Days" DamTimeScale

	# Results
    set results [list REACTION No TEMPERATURE Yes POSITIVE_FACE_PRESSURE Yes]
    set nodal_path [spdAux::getRoute "NodalResults"]
    spdAux::SetValuesOnBasePath $nodal_path $results

    spdAux::RequestRefresh


}

