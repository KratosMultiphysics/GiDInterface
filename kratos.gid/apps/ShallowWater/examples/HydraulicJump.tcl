namespace eval ::ShallowWater::examples::HydraulicJump {
    namespace path ::ShallowWater::examples
    Kratos::AddNamespace [namespace current]
}

proc ::ShallowWater::examples::HydraulicJump::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawGeometry
    AssignGroups
    TreeAssignation

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

proc ::ShallowWater::examples::HydraulicJump::DrawGeometry {args} {
    Kratos::ResetModel
    GiD_Layers create main_layer
    GiD_Layers edit to_use main_layer

    # Geometry creation
    ## Points ##
    set coordinates [list 0 0 0 100 0 0 100 4 0 0 4 0]
    set geom_points [list ]
    foreach {x y z} $coordinates {
        lappend geom_points [GiD_Geometry create point append main_layer $x $y $z]
    }

    ## Lines ##
    set geom_lines [list ]
    set initial [lindex $geom_points 0]
    foreach point [lrange $geom_points 1 end] {
        lappend geom_lines [GiD_Geometry create line append stline main_layer $initial $point]
        set initial $point
    }
    lappend geom_lines [GiD_Geometry create line append stline main_layer $initial [lindex $geom_points 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$geom_lines escape escape
}

proc ::ShallowWater::examples::HydraulicJump::AssignGroups {args} {
    # Create and assign the groups
    GiD_Groups create Channel
    GiD_Groups edit color Channel "#26d1a8ff"
    GiD_EntitiesGroups assign Channel surfaces 1

    GiD_Groups create Walls
    GiD_Groups edit color Walls "#3b3b3bff"
    GiD_EntitiesGroups assign Walls lines {1 3}

    GiD_Groups create Upstream
    GiD_Groups edit color Upstream "#3b3b3bff"
    GiD_EntitiesGroups assign Upstream lines 4

    GiD_Groups create Downstream
    GiD_Groups edit color Downstream "#3b3b3bff"
    GiD_EntitiesGroups assign Downstream lines 2
}

proc ::ShallowWater::examples::HydraulicJump::TreeAssignation {args} {

    # Parts
    set parts [spdAux::getRoute "SWParts"]
    set part_node [customlib::AddConditionGroupOnXPath $parts Channel]
    set props [list Element GENERIC_ELEMENT Material Concrete]
    spdAux::SetValuesOnBaseNode $part_node $props

    # Topography data
    set topography_conditions [spdAux::getRoute "SWTopographicData"]
    set topography_cond "$topography_conditions/condition\[@n='Topography'\]"
    set topography_node [customlib::AddConditionGroupOnXPath $topography_cond Channel]
    $topography_node setAttribute ov surface
    set props [list ByFunction Yes function_value "2.45135310e-07*x**4 -4.82230477e-05*x**3 +2.54997185e-03*x**2 -4.57311854e-02*x +2.73225488e+00"]
    spdAux::SetValuesOnBaseNode $topography_node $props

    # Initial conditions
    set initial_conditions [spdAux::getRoute "SWInitialConditions"]
    set initial_cond "$initial_conditions/condition\[@n='InitialWaterLevel'\]"
    spdAux::AddIntervalGroup Channel "Channel//Initial"
    set initial_node [customlib::AddConditionGroupOnXPath $initial_cond "Channel//Initial"]
    $initial_node setAttribute ov surface
    set props [list variable_name FREE_SURFACE_ELEVATION value 2.8 Interval Initial set_minimum_height 1 minimum_height_value 1] 
    spdAux::SetValuesOnBaseNode $initial_node $props

    # Conditions
    set boundary_conditions [spdAux::getRoute "SWConditions"]
    set flow_rate_cond "$boundary_conditions/condition\[@n='ImposedFlowRate'\]"
    set water_height_cond "$boundary_conditions/condition\[@n='ImposedFreeSurface'\]"

    spdAux::AddIntervalGroup Walls "Walls//Total"
    set flow_rate_node [customlib::AddConditionGroupOnXPath $flow_rate_cond "Walls//Total"]
    $flow_rate_node setAttribute ov line
    set props [list selector_component_X Not value_component_Y 0.0 selector_component_Z Not Interval Total] 
    spdAux::SetValuesOnBaseNode $flow_rate_node $props

    spdAux::AddIntervalGroup Upstream "Upstream//Total"
    set flow_rate_node [customlib::AddConditionGroupOnXPath $flow_rate_cond "Upstream//Total"]
    $flow_rate_node setAttribute ov line
    set props [list value_component_X 2.0 selector_component_Y 0.0 selector_component_Z Not Interval Total] 
    spdAux::SetValuesOnBaseNode $flow_rate_node $props

    spdAux::AddIntervalGroup Downstream "Downstream//Total"
    set free_surface_node [customlib::AddConditionGroupOnXPath $water_height_cond "Downstream//Total"]
    $free_surface_node setAttribute ov line
    set props [list value 2.8 Interval Total] 
    spdAux::SetValuesOnBaseNode $free_surface_node $props

    # Time parameters
    set parameters [list EndTime 50.0]
    set xpath [spdAux::getRoute "SWTimeParameters"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Output
    set parameters [list OutputControlType time OutputDeltaTime 1.0]
    set xpath "[spdAux::getRoute Results]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Refresh
    spdAux::RequestRefresh
}
