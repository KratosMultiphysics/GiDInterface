namespace eval ::MPM::examples::GranularFlow {
    namespace path ::MPM::examples
    Kratos::AddNamespace [namespace current]

}
proc ::MPM::examples::GranularFlow::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawGeometry$::Model::SpatialDimension
    AssignGroups$::Model::SpatialDimension
    TreeAssignation$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc ::MPM::examples::GranularFlow::DrawGeometry3D {args} {
    # DrawGranularFlowGeometry2D
    # GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape escape escape
    # GiD_Layers edit opaque Fluid 0

    # GiD_Process escape escape 'Render Flat escape 'Rotate Angle 270 90 escape escape escape escape 'Rotate objaxes x -150 y -30 escape escape
}
proc ::MPM::examples::GranularFlow::DrawGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create GranularMaterial
    GiD_Layers edit to_use GranularMaterial
    GiD_Layers edit color GranularMaterial "#e1aa72"

    # GranularMaterial square
    ## Points ##
    set coordinates [list {0 0 0} {0 0.1 0} {0.2 0.1 0} {0.2 0 0}]
    set material_points [list ]
    foreach point $coordinates {
        lappend material_points [GiD_Geometry create point append GranularMaterial {*}$point]
    }

    ## Lines ##
    set material_lines [list ]
    set initial [lindex $material_points 0]
    foreach point [lrange $material_points 1 end] {
        lappend material_lines [GiD_Geometry create line append stline GranularMaterial $initial $point]
        set initial $point
    }
    lappend material_lines [GiD_Geometry create line append stline GranularMaterial $initial [lindex $material_points 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$material_lines escape escape


    # Grid creation
    GiD_Layers create Grid
    GiD_Layers edit to_use Grid
    GiD_Layers edit color Grid "#fddda0"

    ## Points ##
    set coordinates [list {0 0.0 0} {0 0.15 0} {0.55 0.15 0} {0.55 0 0}]
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
proc ::MPM::examples::GranularFlow::AssignGroups2D {args} {
    # Create the groups
    GiD_Groups create GranularMaterial
    GiD_Groups edit color GranularMaterial "#26d1a8ff"
    GiD_EntitiesGroups assign GranularMaterial surfaces 1

    GiD_Groups create Grid
    GiD_Groups edit color Grid "#e0210fff"
    GiD_EntitiesGroups assign Grid surfaces {2}

    GiD_Groups create FixedDisplacement
    GiD_Groups edit color FixedDisplacement "#3b3b3bff"
    GiD_EntitiesGroups assign FixedDisplacement lines {5 8}
}

proc ::MPM::examples::GranularFlow::AssignGroups3D {args} {

}

# Tree assign
proc ::MPM::examples::GranularFlow::TreeAssignation3D {args} {
    TreeAssignation2D
}

proc ::MPM::examples::GranularFlow::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # StageInfo
    spdAux::SetValueOnTreeItem v "Dynamic" MPMSoluType

    # Parts
    set mpm_parts_route [spdAux::getRoute "MPMParts"]

    # Erase Intervals
    ErasePreviousIntervals

    ## GranularMaterial
    set mpm_solid_parts_route "${mpm_parts_route}/condition\[@n='Parts_Material_domain'\]"
    set mpm_solid_part [customlib::AddConditionGroupOnXPath $mpm_solid_parts_route GranularMaterial]
    $mpm_solid_part setAttribute ov surface
    set constitutive_law_name "HenckyMCPlasticPlaneStrain${nd}Law"
    set props [list Element MPMUpdatedLagrangian$nd ConstitutiveLaw $constitutive_law_name Material GranularMaterial DENSITY 2650 YOUNG_MODULUS 840000 POISSON_RATIO 0.3 INTERNAL_FRICTION_ANGLE 19.8 THICKNESS 0.1 PARTICLES_PER_ELEMENT 3]
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
    spdAux::AddIntervalGroup FixedDisplacement "FixedDisplacement"
    GiD_Groups edit state "FixedDisplacement" hidden

    ## Assign boundary condition
    set mpm_bc_route [spdAux::getRoute "MPMNodalConditions"]
    set mpm_displacement_route "${mpm_bc_route}/condition\[@n='DISPLACEMENT'\]"
    set mpm_displacement [customlib::AddConditionGroupOnXPath $mpm_displacement_route "FixedDisplacement"]
    $mpm_displacement setAttribute ov $condtype
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0  selector_component_Z ByValue value_component_Z 0.0]
    spdAux::SetValuesOnBaseNode $mpm_displacement $props

    # Set gravity On
    spdAux::SetValueOnTreeItem v "On" ActivateGravity

    # Solution strategy parameters
    spdAux::SetValueOnTreeItem v "0.00005" MPTimeParameters DeltaTime
    spdAux::SetValueOnTreeItem v "2" MPTimeParameters EndTime
    spdAux::SetValueOnTreeItem v "time" GiDOptions OutputControlType
    spdAux::SetValueOnTreeItem v "0.01" GiDOptions OutputDeltaTime
    spdAux::SetValueOnTreeItem v "time" VtkOptions OutputControlType
    spdAux::SetValueOnTreeItem v "0.01" VtkOptions OutputDeltaTime
}
