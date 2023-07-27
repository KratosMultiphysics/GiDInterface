namespace eval ::Dam::examples::ThermoMechaDam3D {
    namespace path ::Dam::examples
    Kratos::AddNamespace [namespace current]

}

proc ::Dam::examples::ThermoMechaDam3D::Init {args} {
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

proc ::Dam::examples::ThermoMechaDam3D::DrawGeometry {args} {

    Kratos::ResetModel

    # Dam #
    GiD_Layers create Dam
    GiD_Layers edit to_use Dam

    # Geometry creation
    ## Points ##
    set dam_coordinates [list {0 0 0} {22.8 0 0} {6 0 21} {6 0 31.1} {0 0 31.1} ]
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
    set ground_coordinates [list {-35.8 0 0} {-35.8 0 -31} {57.50385 0 -31} {57.50385 0 0} ]
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

    GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,15,0.0 2 1 Mescape Mescape

    # Swap normals of hydrostatic pressure and heat flux surfaces to point outside the volume
    GiD_Process Mescape Utilities SwapNormals Surfaces Select 4 escape escape
    GiD_Process Mescape Utilities SwapNormals Surfaces Select 5 escape escape
    GiD_Process Mescape Utilities SwapNormals Surfaces Select 6 escape escape
    GiD_Process Mescape Utilities SwapNormals Surfaces Select 7 escape escape
    GiD_Process Mescape Utilities SwapNormals Surfaces Select 8 escape escape
    GiD_Process Mescape Utilities SwapNormals Surfaces Select 12 escape escape

    GiD_Process 'Rotate Angle 270 0
    GiD_Process 'Zoom Frame

}

proc ::Dam::examples::ThermoMechaDam3D::AssignGroups {args} {

    # Create the groups
    GiD_Groups create Dam
    GiD_Groups edit color Dam "#26d1a8ff"
    GiD_EntitiesGroups assign Dam volumes 1

    GiD_Groups create Ground
    GiD_Groups edit color Ground "#e0210fff"
    GiD_EntitiesGroups assign Ground volumes 2

    GiD_Groups create Displacement
    GiD_Groups edit color Displacement "#3b3b3bff"
    GiD_EntitiesGroups assign Displacement surfaces 10

    GiD_Groups create AmbientHeatFlux
    GiD_Groups edit color AmbientHeatFlux "#3b3b3bff"
    GiD_EntitiesGroups assign AmbientHeatFlux surfaces {4 5 6 7 8 12}

    GiD_Groups create Water
    GiD_Groups edit color Water "#3b3b3bff"
    GiD_EntitiesGroups assign Water surfaces {7 8}

}

proc ::Dam::examples::ThermoMechaDam3D::AssignMeshSizes {args} {

    set dam_mesh_size 2
    GiD_Process Mescape Meshing AssignSizes Volumes $dam_mesh_size 1:end escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $dam_mesh_size 1:end escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $dam_mesh_size 1:end escape escape
    ##Kratos::BeforeMeshGeneration $dam_mesh_size
}

# Tree assign
proc ::Dam::examples::ThermoMechaDam3D::TreeAssignation {args} {

    set nd $::Model::SpatialDimension
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

        set ground_temperature [customlib::AddConditionGroupOnXPath $temperature_base Ground]
        set props_ground_temperature [list is_fixed false value 7.5 ]
        spdAux::SetValuesOnBaseNode $ground_temperature $props_ground_temperature

        # Constant Temperature
        set water_path "$damDirichletConditions/condition\[@n='CONSTANTRESERVOIRTEMPERATURE'\]"
        set water_node [customlib::AddConditionGroupOnXPath $water_path Water]
        set props_water [list is_fixed true Gravity_Direction Z Reservoir_Bottom_Coordinate_in_Gravity_Direction 0.0 Water_temp 6 Water_level 15]
        spdAux::SetValuesOnBaseNode $water_node $props_water

    # Load Conditions

        # Hydrostatic Load
        set damLoadConditions [spdAux::getRoute "DamLoads"]
        set hydrostatic_load "$damLoadConditions/condition\[@n='HydroSurfacePressure3D'\]"
        set hydrostatic_load_node [customlib::AddConditionGroupOnXPath $hydrostatic_load Water]
        set props_hydrostatic_load [list Modify true Gravity_Direction Z Reservoir_Bottom_Coordinate_in_Gravity_Direction 0.0 Spe_weight 10000 Water_level 25.0]
        spdAux::SetValuesOnBaseNode $hydrostatic_load_node $props_hydrostatic_load

    # Thermal Load Conditions

        # Thermal Parameters Dam
        set damThermalLoadConditions [spdAux::getRoute "DamThermalLoads"]
        set thermal_load "$damThermalLoadConditions/condition\[@n='ThermalParameters3D'\]"
        set dam_thermal_node [customlib::AddConditionGroupOnXPath $thermal_load Dam]
        set props_dam_thermal [list ThermalDensity 2400 Conductivity 1.0 SpecificHeat 1000.0]
        spdAux::SetValuesOnBaseNode $dam_thermal_node $props_dam_thermal

        # Thermal Parameters Ground
        set ground_thermal_node [customlib::AddConditionGroupOnXPath $thermal_load Ground]
        set props_ground_thermal [list ThermalDensity 3000 Conductivity 1.0 SpecificHeat 1000.0]
        spdAux::SetValuesOnBaseNode $ground_thermal_node $props_ground_thermal


        # Ambient flux
        set ambient_flux_load "$damThermalLoadConditions/condition\[@n='TAmbientFlux3D'\]"
        set ambient_flux_node [customlib::AddConditionGroupOnXPath $ambient_flux_load AmbientHeatFlux]
        set props_ambient_flux [list h_0 3.5 ambient_temperature 10.0 ]
        spdAux::SetValuesOnBaseNode $ambient_flux_node $props_ambient_flux


    # Reference temperature

        # Reference temperature Dam
        set dam_reference_temperature "$damThermalLoadConditions/condition\[@n='NodalReferenceTemperature3D'\]"
        set dam_reference_temperature_node [customlib::AddConditionGroupOnXPath $dam_reference_temperature Dam]
        set props_dam_reference_temperature [list initial_value 7.5 ]
        spdAux::SetValuesOnBaseNode $dam_reference_temperature_node $props_dam_reference_temperature

        # Reference temperature Ground
        set ground_reference_temperature "$damThermalLoadConditions/condition\[@n='NodalReferenceTemperature3D'\]"
        set ground_reference_temperature_node [customlib::AddConditionGroupOnXPath $ground_reference_temperature Ground]
        set props_ground_reference_temperature [list initial_value 7.5 ]
        spdAux::SetValuesOnBaseNode $ground_reference_temperature_node $props_ground_reference_temperature


    # Solution
    spdAux::SetValueOnTreeItem v "Days" DamTimeScale

    # Results
    set results [list REACTION No TEMPERATURE Yes POSITIVE_FACE_PRESSURE Yes]
    set nodal_path [spdAux::getRoute "NodalResults"]
    spdAux::SetValuesOnBasePath $nodal_path $results
    spdAux::SetValueOnTreeItem v SingleFile GiDOptions GiDMultiFileFlag

    spdAux::RequestRefresh


}

