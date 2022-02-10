namespace eval ::ShallowWater::examples::Waves {
    namespace path ::ShallowWater::examples
    Kratos::AddNamespace [namespace current]
}

proc ::ShallowWater::examples::Waves::Init {args} {
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

proc ::ShallowWater::examples::Waves::DrawGeometry {args} {
    Kratos::ResetModel
    GiD_Layers create main_layer
    GiD_Layers edit to_use main_layer

    # Geometry creation
    ## Points ##
    set coordinates [list 0 0 0 10 0 0 10 10 0 0 10 0]
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
    lappend geom_lines [GiD_Geometry create line append stline main_layer $initial [lindex $geom_points_left 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$geom_lines escape escape
}

proc ::ShallowWater::examples::Waves::AssignGroups {args} {
    # Create and assign the groups
    GiD_Groups create Body
    GiD_Groups edit color Body "#26d1a8ff"
    GiD_EntitiesGroups assign Body surfaces 1

    GiD_Groups create Walls
    GiD_Groups edit color Walls "#3b3b3bff"
    GiD_EntitiesGroups assign Walls lines {1 2 3 4}
}

proc ::ShallowWater::examples::Waves::TreeAssignation {args} {

    # Parts
    set parts [spdAux::getRoute "SWParts"]
    set part_node [customlib::AddConditionGroupOnXPath $parts Body]
    set props [list Element GENERIC_ELEMENT Material Concrete]
    spdAux::SetValuesOnBaseNode $part_node $props

    # Initial conditions
    set initial_conditions [spdAux::getRoute "SWInitialConditions"]
    set initial_cond "$initial_conditions/condition\[@n='InitialWaterLevel'\]"
    spdAux::AddIntervalGroup Body "Body//Initial"
    set initial_node [customlib::AddConditionGroupOnXPath $initial_cond "Body//Initial"]
    $initial_node setAttribute ov surface
    set props [list value 1.0 Interval Initial] 
    spdAux::SetValuesOnBaseNode $initial_node $props

    # Conditions
    set boundary_conditions [spdAux::getRoute "SWConditions"]
    set flow_rate_cond "$boundary_conditions/condition\[@n='ImposedFlowRate'\]"
    spdAux::AddIntervalGroup Walls "Walls//Total"
    set flow_rate_node [customlib::AddConditionGroupOnXPath $flow_rate_cond "Walls//Total"]
    $flow_rate_node setAttribute ov line
    set props [list selector_component_X Not value_component_Y 0.0 Interval Total] 
    spdAux::SetValuesOnBaseNode $flow_rate_node $props

    # spdAux::AddIntervalGroup Right "Right//Total"
    # set flow_rate_node [customlib::AddConditionGroupOnXPath $flow_rate_cond "Right//Total"]
    # $flow_rate_node setAttribute ov line
    # set props [list value_component_X 0.0 selector_component_Y Not Interval Total] 
    # spdAux::SetValuesOnBaseNode $flow_rate_node $props

    # spdAux::AddIntervalGroup Left "Left//Total"
    # set flow_rate_node [customlib::AddConditionGroupOnXPath $flow_rate_cond "Left//Total"]
    # $flow_rate_node setAttribute ov line
    # set props [list value_component_X 0.0 selector_component_Y Not Interval Total] 
    # spdAux::SetValuesOnBaseNode $flow_rate_node $props

    # Refresh
    spdAux::RequestRefresh
}
