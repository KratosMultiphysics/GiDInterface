namespace eval ::ShallowWater::examples::DamBreak {
    namespace path ::ShallowWater::examples
    Kratos::AddNamespace [namespace current]
}

proc ::ShallowWater::examples::DamBreak::Init {args} {
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

proc ::ShallowWater::examples::DamBreak::DrawGeometry {args} {
    Kratos::ResetModel
    GiD_Layers create main_layer
    GiD_Layers edit to_use main_layer

    # Geometry creation
    ## Points ##
    set coordinates_left [list 0 0 0 5 0 0 5 1 0 0 1 0]
    set geom_points_left [list ]
    foreach {x y z} $coordinates_left {
        lappend geom_points_left [GiD_Geometry create point append main_layer $x $y $z]
    }

    set coordinates_right [list 5 0 0 10 0 0 10 1 0 5 1 0]
    set geom_points_right [list ]
    foreach {x y z} $coordinates_right {
        lappend geom_points_right [GiD_Geometry create point append main_layer $x $y $z]
    }

    ## Lines ##
    set geom_lines_left [list ]
    set initial [lindex $geom_points_left 0]
    foreach point [lrange $geom_points_left 1 end] {
        lappend geom_lines_left [GiD_Geometry create line append stline main_layer $initial $point]
        set initial $point
    }
    lappend geom_lines_left [GiD_Geometry create line append stline main_layer $initial [lindex $geom_points_left 0]]

    set geom_lines_right [list ]
    set initial [lindex $geom_points_right 0]
    foreach point [lrange $geom_points_right 1 end] {
        lappend geom_lines_right [GiD_Geometry create line append stline main_layer $initial $point]
        set initial $point
    }
    lappend geom_lines_right [GiD_Geometry create line append stline main_layer $initial [lindex $geom_points_right 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$geom_lines_left escape escape
    GiD_Process Mescape Geometry Create NurbsSurface {*}$geom_lines_right escape escape

    ## Remove the duplicated line
    GiD_Process Mescape Utilities Collapse model Yes
}

proc ::ShallowWater::examples::DamBreak::AssignGroups {args} {
    # Create and assign the groups
    GiD_Groups create Body
    GiD_Groups edit color Body "#26d1a8ff"
    GiD_EntitiesGroups assign Body surfaces {1 2}

    GiD_Groups create Reservoir
    GiD_Groups edit color Reservoir "#26d1a8ff"
    GiD_EntitiesGroups assign Reservoir surfaces 1

    GiD_Groups create Channel
    GiD_Groups edit color Channel "#26d1a8ff"
    GiD_EntitiesGroups assign Channel surfaces 2

    GiD_Groups create Walls
    GiD_Groups edit color Walls "#3b3b3bff"
    GiD_EntitiesGroups assign Walls lines {1 3 5 7}

    GiD_Groups create Left
    GiD_Groups edit color Left "#3b3b3bff"
    GiD_EntitiesGroups assign Left lines 4

    GiD_Groups create Right
    GiD_Groups edit color Right "#3b3b3bff"
    GiD_EntitiesGroups assign Right lines 6
}

proc ::ShallowWater::examples::DamBreak::TreeAssignation {args} {

    # Parts
    set parts [spdAux::getRoute "SWParts"]
    set part_node [customlib::AddConditionGroupOnXPath $parts Body]
    set props [list Element GENERIC_ELEMENT Material Concrete]
    spdAux::SetValuesOnBaseNode $part_node $props

    # Topography data
    set topography_conditions [spdAux::getRoute "SWTopographicData"]
    set topography_cond "$topography_conditions/condition\[@n='Topography'\]"
    set topography_node [customlib::AddConditionGroupOnXPath $topography_cond Body]
    $topography_node setAttribute ov surface
    set props [list value 0.0]
    spdAux::SetValuesOnBaseNode $topography_node $props

    # Initial conditions
    set initial_conditions [spdAux::getRoute "SWInitialConditions"]
    set initial_cond "$initial_conditions/condition\[@n='InitialWaterLevel'\]"
    spdAux::AddIntervalGroup Reservoir "Reservoir//Initial"
    set initial_node [customlib::AddConditionGroupOnXPath $initial_cond "Reservoir//Initial"]
    $initial_node setAttribute ov surface
    set props [list value 1.0 Interval Initial] 
    spdAux::SetValuesOnBaseNode $initial_node $props

    spdAux::AddIntervalGroup Channel "Channel//Initial"
    set initial_node [customlib::AddConditionGroupOnXPath $initial_cond "Channel//Initial"]
    $initial_node setAttribute ov surface
    set props [list value 0.8 Interval Initial] 
    spdAux::SetValuesOnBaseNode $initial_node $props

    # Conditions
    set boundary_conditions [spdAux::getRoute "SWConditions"]
    set flow_rate_cond "$boundary_conditions/condition\[@n='ImposedFlowRate'\]"
    spdAux::AddIntervalGroup Walls "Walls//Total"
    set flow_rate_node [customlib::AddConditionGroupOnXPath $flow_rate_cond "Walls//Total"]
    $flow_rate_node setAttribute ov line
    set props [list selector_component_X Not value_component_Y 0.0 selector_component_Z Not Interval Total] 
    spdAux::SetValuesOnBaseNode $flow_rate_node $props

    spdAux::AddIntervalGroup Right "Right//Total"
    set flow_rate_node [customlib::AddConditionGroupOnXPath $flow_rate_cond "Right//Total"]
    $flow_rate_node setAttribute ov line
    set props [list value_component_X 0.0 selector_component_Y Not selector_component_Z Not Interval Total] 
    spdAux::SetValuesOnBaseNode $flow_rate_node $props

    spdAux::AddIntervalGroup Left "Left//Total"
    set flow_rate_node [customlib::AddConditionGroupOnXPath $flow_rate_cond "Left//Total"]
    $flow_rate_node setAttribute ov line
    set props [list value_component_X 0.0 selector_component_Y Not selector_component_Z Not Interval Total] 
    spdAux::SetValuesOnBaseNode $flow_rate_node $props

    # Time parameters
    set parameters [list EndTime 2.0]
    set xpath [spdAux::getRoute "SWTimeParameters"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Output
    set parameters [list OutputControlType time OutputDeltaTime 0.1]
    set xpath "[spdAux::getRoute Results]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Refresh
    spdAux::RequestRefresh
}
