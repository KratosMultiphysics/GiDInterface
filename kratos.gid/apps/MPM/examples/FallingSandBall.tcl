
proc ::MPM::examples::FallingSandBall {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawFallingSandBallGeometry$::Model::SpatialDimension
    AssignGroupsFallingSandBall$::Model::SpatialDimension
    TreeAssignationFallingSandBall$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc MPM::examples::DrawFallingSandBallGeometry3D {args} {
    # DrawFallingSandBallGeometry2D
    # GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape escape escape
    # GiD_Layers edit opaque Fluid 0

    # GiD_Process escape escape 'Render Flat escape 'Rotate Angle 270 90 escape escape escape escape 'Rotate obj x -150 y -30 escape escape
}
proc MPM::examples::DrawFallingSandBallGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Sand
    GiD_Layers edit to_use Sand
    GiD_Layers edit color Sand "#e1aa72"

    # Sand circle
    GiD_Process Mescape Geometry Create Object CirclePNR 2.0 3.0 0.0 0.0 0.0 1.0 0.5 escape escape 


    # Grid creation
    GiD_Layers create Grid
    GiD_Layers edit to_use Grid
    GiD_Layers edit color Grid "#fddda0"
    
    ## Points ##
    set coordinates [list {0 0 0} {0 4 0} {4 4 0} {4 0 0}]
    set grid_points [list ]
    foreach point $coordinates {
        lappend grid_points [GiD_Geometry create point append Grid {*}$point]
    }

    ## Lines ##
    set grid_lines [list ]
    set initial [lindex $grid_points 0]
    foreach point [lrange $grid_points 1 end] {
        lappend grid_lines [GiD_Geometry create line append stline Grid $initial $point]
        set initial $point
    }
    lappend grid_lines [GiD_Geometry create line append stline Grid $initial [lindex $grid_points 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$grid_lines escape escape
}


# Group assign
proc MPM::examples::AssignGroupsFallingSandBall2D {args} {
    # Create the groups
    GiD_Groups create Sand
    GiD_Groups edit color Sand "#26d1a8ff"
    GiD_EntitiesGroups assign Sand surfaces 1

    GiD_Groups create Grid
    GiD_Groups edit color Grid "#e0210fff"
    GiD_EntitiesGroups assign Grid surfaces 2

    GiD_Groups create FixedDisplacement
    GiD_Groups edit color FixedDisplacement "#3b3b3bff"
    GiD_EntitiesGroups assign FixedDisplacement lines 5

    GiD_Groups create Slip
    GiD_Groups edit color Slip "#42eb71ff"
    GiD_EntitiesGroups assign Slip lines {2 4}
}

proc MPM::examples::AssignGroupsFallingSandBall3D {args} {
    
}

# Tree assign
proc MPM::examples::TreeAssignationFallingSandBall3D {args} {
    TreeAssignationFallingSandBall2D
}

proc MPM::examples::TreeAssignationFallingSandBall2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # StageInfo
    spdAux::SetValueOnTreeItem v "Dynamic" MPMSoluType

    # Parts
    set mpm_parts_route [spdAux::getRoute "MPMParts"]

    ## Sand
    set mpm_solid_parts_route "${mpm_parts_route}/condition\[@n='Parts_Solid'\]"
    set mpm_solid_part [customlib::AddConditionGroupOnXPath $mpm_solid_parts_route Sand]
    $mpm_solid_part setAttribute ov surface
    set constitutive_law_name "HenckyMCPlasticPlaneStrain${nd}Law"
    set props [list Element UpdatedLagrangian$nd ConstitutiveLaw $constitutive_law_name Material Sand DENSITY 2300 YOUNG_MODULUS 6e6 POISSON_RATIO 0.3 THICKNESS 0.1 PARTICLES_PER_ELEMENT 10]
    spdAux::SetValuesOnBaseNode $mpm_solid_part $props

    ## Grid
    set mpm_grid_parts_route "${mpm_parts_route}/condition\[@n='Parts_Grid'\]"
    set mpm_grid_part [customlib::AddConditionGroupOnXPath $mpm_grid_parts_route Grid]
    $mpm_grid_part setAttribute ov surface
    set props [list Element GRID$nd ]
    spdAux::SetValuesOnBaseNode $mpm_grid_part $props

    
    # Fix Displacement
    ## Create interval subgroup
    GiD_Groups clone FixedDisplacement Total
    GiD_Groups edit parent Total FixedDisplacement
    spdAux::AddIntervalGroup FixedDisplacement "FixedDisplacement//Total"
    GiD_Groups edit state "FixedDisplacement//Total" hidden

    ## Assign boundary condition
    set mpm_bc_route [spdAux::getRoute "MPMNodalConditions"]
    set mpm_displacement_route "${mpm_bc_route}/condition\[@n='DISPLACEMENT'\]"
    set mpm_displacement [customlib::AddConditionGroupOnXPath $mpm_displacement_route "FixedDisplacement//Total"]
    $mpm_displacement setAttribute ov $condtype
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0  selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $mpm_displacement $props

    ## Slip
    set mpm_loads_route [spdAux::getRoute "MPMLoads"]
    [customlib::AddConditionGroupOnXPath "$mpm_loads_route/condition\[@n='Slip$nd'\]" Slip] setAttribute ov $condtype

    # Solution strategy parameters
    spdAux::SetValueOnTreeItem v "0.005" MPMTimeParameters DeltaTime
    spdAux::SetValueOnTreeItem v "0.01" GiDOptions OutputDeltaTime
}

proc MPM::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}