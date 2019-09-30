
proc ::Solid::examples::StaticBeamLattice {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawStaticBeamLatticeGeometry$::Model::SpatialDimension
    TreeAssignationStaticBeamLattice$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc Solid::examples::DrawStaticBeamLatticeGeometry3D {args} {
    Kratos::ResetModel
    set dir [apps::getMyDir "Solid"]
    set problemfile [file join $dir examples StaticBeamLattice.gid]
    GiD_Process Mescape Files InsertGeom $problemfile
}
proc Solid::examples::DrawStaticBeamLatticeGeometry2Da {args} {
    Kratos::ResetModel
}
proc Solid::examples::DrawStaticBeamLatticeGeometry2D {args} {
    Kratos::ResetModel
}
# Mesh sizes


# Tree assign
proc Solid::examples::TreeAssignationStaticBeamLattice3D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype point

    # Static solution strategy set
    spdAux::SetValueOnTreeItem v "Quasi-static" SLSoluType
    spdAux::SetValueOnTreeItem v "StaticStep" SLScheme

    # Time parameters
    set time_parameters [list EndTime 1.6e2 DeltaTime 5.0]
    set time_params_path [spdAux::getRoute SLTimeParameters]
    foreach {name value} $time_parameters {
        set node [$root selectNodes "$time_params_path/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check  example script"
        }
    }

    # Solid Parts
    set solidParts [spdAux::getRoute "SLParts"]
    set solidPartsNode [customlib::AddConditionGroupOnXPath $solidParts Wires]
    $solidPartsNode setAttribute ov line
    set props [list Element LargeDisplacementBeamElement3D ConstitutiveLaw UserDefined3D DENSITY 2650 CROSS_SECTION_AREA 7.85e-4 YOUNG_MODULUS 83.0e15 INERTIA_X 4.9E-6 INERTIA_Y 4.9E-6]
    foreach {prop val} $props {
        set propnode [$solidPartsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Solid $prop"
        }
    }

    set solidPartsNode [customlib::AddConditionGroupOnXPath $solidParts Connectors]
    $solidPartsNode setAttribute ov line
    set props [list Element LargeDisplacementBeamElement3D ConstitutiveLaw UserDefined3D DENSITY 2650 CROSS_SECTION_AREA 7.85e-4 YOUNG_MODULUS 83.0e15 INERTIA_X 1.0E-6 INERTIA_Y 1.0E-6]
    foreach {prop val} $props {
        set propnode [$solidPartsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Solid $prop"
        }
    }

    spdAux::RequestRefresh
    set solidConditions [spdAux::getRoute "SLNodalConditions"]

    # Solid Constraint
    GiD_Groups clone Displacement1 Total
    GiD_Groups edit parent Total Displacement1
    spdAux::AddIntervalGroup Displacement1 "Displacement1//Total"
    GiD_Groups edit state "Displacement1//Total" hidden
    set solidConstraint {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintNode [customlib::AddConditionGroupOnXPath $solidConstraint "Displacement1//Total"]
    $solidConstraintNode setAttribute ov point
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$solidConstraintNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    GiD_Groups clone Displacement2 Total
    GiD_Groups edit parent Total Displacement2
    spdAux::AddIntervalGroup Displacement2 "Displacement2//Total"
    GiD_Groups edit state "Displacement2//Total" hidden
    set solidConstraint {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintNode [customlib::AddConditionGroupOnXPath $solidConstraint "Displacement2//Total"]
    $solidConstraintNode setAttribute ov point
    set props [list selector_component_X Not selector_component_Y ByFunction function_component_Y "1.0e-2*t" selector_component_Z Not Interval Total]
    foreach {prop val} $props {
         set propnode [$solidConstraintNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    GiD_Groups clone Displacement3 Total
    GiD_Groups edit parent Total Displacement3
    spdAux::AddIntervalGroup Displacement3 "Displacement3//Total"
    GiD_Groups edit state "Displacement3//Total" hidden
    set solidConstraint {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintNode [customlib::AddConditionGroupOnXPath $solidConstraint "Displacement3//Total"]
    $solidConstraintNode setAttribute ov point
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$solidConstraintNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    GiD_Groups clone Displacement4 Total
    GiD_Groups edit parent Total Displacement4
    spdAux::AddIntervalGroup Displacement4 "Displacement4//Total"
    GiD_Groups edit state "Displacement4//Total" hidden
    set solidConstraint {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintNode [customlib::AddConditionGroupOnXPath $solidConstraint "Displacement4//Total"]
    $solidConstraintNode setAttribute ov point
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByFunction function_component_Y "1.0e-2*t" selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$solidConstraintNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    GiD_Groups clone Displacement5 Total
    GiD_Groups edit parent Total Displacement5
    spdAux::AddIntervalGroup Displacement5 "Displacement5//Total"
    GiD_Groups edit state "Displacement5//Total" hidden
    set solidConstraint {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintNode [customlib::AddConditionGroupOnXPath $solidConstraint "Displacement5//Total"]
    $solidConstraintNode setAttribute ov point
    set props [list selector_component_X Not value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z Not Interval Total]
    foreach {prop val} $props {
         set propnode [$solidConstraintNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    GiD_Groups clone Displacement6 Total
    GiD_Groups edit parent Total Displacement6
    spdAux::AddIntervalGroup Displacement6 "Displacement6//Total"
    GiD_Groups edit state "Displacement6//Total" hidden
    set solidConstraint {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintNode [customlib::AddConditionGroupOnXPath $solidConstraint "Displacement6//Total"]
    $solidConstraintNode setAttribute ov point
    set props [list selector_component_X Not selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$solidConstraintNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    # Parallelism
    set time_parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set time_params_path [spdAux::getRoute "Parallelization"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }


    spdAux::RequestRefresh
}
proc Solid::examples::TreeAssignationStaticBeamLattice2Da {args} {
    Kratos::ResetModel
}
proc Solid::examples::TreeAssignationStaticBeamLattice2D {args} {
    Kratos::ResetModel
}
