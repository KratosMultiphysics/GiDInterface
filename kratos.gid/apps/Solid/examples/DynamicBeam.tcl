
proc ::Solid::examples::DynamicBeam {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawDynamicBeamGeometry$::Model::SpatialDimension
    TreeAssignationDynamicBeam$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc Solid::examples::DrawDynamicBeamGeometry3D {args} {
    Kratos::ResetModel
    set dir [apps::getMyDir "Solid"]
    set problemfile [file join $dir examples DynamicBeam3D.gid]
    GiD_Process Mescape Files InsertGeom $problemfile
}
proc Solid::examples::DrawDynamicBeamGeometry2Da {args} {
    Kratos::ResetModel
}
proc Solid::examples::DrawDynamicBeamGeometry2D {args} {
    Kratos::ResetModel
}
# Mesh sizes


# Tree assign
proc Solid::examples::TreeAssignationDynamicBeam3D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype point

    # Static solution strategy set
    spdAux::SetValueOnTreeItem v "Dynamic" SLSoluType
    spdAux::SetValueOnTreeItem v "SimoStep" SLScheme

    # Time parameters
    set time_parameters [list EndTime 5.0 DeltaTime 0.05]
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
    set solidPartsNode [customlib::AddConditionGroupOnXPath $solidParts Solid]
    $solidPartsNode setAttribute ov line
    set props [list Element LargeDisplacementBeamElement3D ConstitutiveLaw CircularSection3D DIAMETER 0.05 YOUNG_MODULUS 206.9e8]
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
    GiD_Groups clone Constraint Total
    GiD_Groups edit parent Total Constraint
    spdAux::AddIntervalGroup Constraint "Constraint//Total"
    GiD_Groups edit state "Constraint//Total" hidden
    set solidConstraint {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintNode [customlib::AddConditionGroupOnXPath $solidConstraint "Constraint//Total"]
    $solidConstraintNode setAttribute ov point
    set props [list Enabled_X Yes ByFunctionX No valueX 0.0 Enabled_Y Yes ByFunctionY No valueY 0.0 Enabled_Z Yes ByFunctionZ No valueZ 0.0]
    foreach {prop val} $props {
         set propnode [$solidConstraintNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    GiD_Groups clone AngularConstraint Total
    GiD_Groups edit parent Total AngularConstraint
    spdAux::AddIntervalGroup AngularConstraint "AngularConstraint//Total"
    GiD_Groups edit state "AngularConstraint//Total" hidden
    set solidAngularConstraint {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='ANGULAR_VELOCITY']}
    set solidAngularConstraintNode [customlib::AddConditionGroupOnXPath $solidAngularConstraint "AngularConstraint//Total"]
    $solidAngularConstraintNode setAttribute ov point
    set props [list Enabled_X Yes ByFunctionX No valueX 2.0 Enabled_Y Yes ByFunctionY No valueY 0.0 Enabled_Z Yes ByFunctionZ No valueZ 0.0]
    foreach {prop val} $props {
         set propnode [$solidAngularConstraintNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    # Solid Loads
    GiD_Groups clone SelfWeight Total
    GiD_Groups edit parent Total SelfWeight 
    spdAux::AddIntervalGroup SelfWeight "SelfWeight//Total"
    GiD_Groups edit state "SelfWeight//Total" hidden
    set solidLoad "container\[@n='Solid'\]/container\[@n='Loads'\]/condition\[@n='SelfWeight$nd'\]"
    set solidLoadNode [customlib::AddConditionGroupOnXPath $solidLoad "SelfWeight//Total"]
    $solidLoadNode setAttribute ov line
    set props [list ByFunction No modulus 9.81 direction 0.0,-1.0,0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$solidLoadNode selectNodes "./value\[@n = '$prop'\]"]
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
proc Solid::examples::TreeAssignationDynamicBeam2Da {args} {
    Kratos::ResetModel
}
proc Solid::examples::TreeAssignationDynamicBeam2D {args} {
    Kratos::ResetModel
}
