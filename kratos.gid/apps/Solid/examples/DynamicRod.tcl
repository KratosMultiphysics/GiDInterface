
proc ::Solid::examples::DynamicRod {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawDynamicRodGeometry$::Model::SpatialDimension
    TreeAssignationDynamicRod$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc Solid::examples::DrawDynamicRodGeometry3D {args} {
    Kratos::ResetModel
    set dir [apps::getMyDir "Solid"]
    set problemfile [file join $dir examples DynamicRod3D.gid]
    GiD_Process Mescape Files InsertGeom $problemfile
}
proc Solid::examples::DrawDynamicRodGeometry2D {args} {
    Kratos::ResetModel
    set dir [apps::getMyDir "Solid"]
    set problemfile [file join $dir examples DynamicRod2D.gid]
    GiD_Process Mescape Files InsertGeom $problemfile
}
proc Solid::examples::DrawDynamicRodGeometry2Da {args} {
    Kratos::ResetModel
}
# Mesh sizes


# Tree assign
proc Solid::examples::TreeAssignationDynamicRod3D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Dynamic solution strategy set
    spdAux::SetValueOnTreeItem v "Dynamic" SLSoluType

    # Time parameters
    set time_parameters [list EndTime 1.06 DeltaTime 0.01]
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
    $solidPartsNode setAttribute ov volume
    set props [list Element TotalLagrangianElement$nd ConstitutiveLaw LargeStrain3DLaw.SaintVenantKirchhoffModel]
    foreach {prop val} $props {
        set propnode [$solidPartsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Solid $prop"
        }
    }

    set solidConditions [spdAux::getRoute "SLNodalConditions"]

    # Solid Constraint
    GiD_Groups clone Constraint Total
    GiD_Groups edit parent Total Constraint
    spdAux::AddIntervalGroup Constraint "Constraint//Total"
    GiD_Groups edit state "Constraint//Total" hidden
    set solidConstraint {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintNode [customlib::AddConditionGroupOnXPath $solidConstraint "Constraint//Total"]
    $solidConstraintNode setAttribute ov line
    set props [list Enabled_X Yes ByFunctionX No valueX 0.0 Enabled_Y Yes ByFunctionY No valueY 0.0 Enabled_Z Yes ByFunctionZ No valueZ 0.0]
    foreach {prop val} $props {
         set propnode [$solidConstraintNode selectNodes "./value\[@n = '$prop'\]"]
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
    $solidLoadNode setAttribute ov volume
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
proc Solid::examples::TreeAssignationDynamicRod2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Dynamic solution strategy set
    spdAux::SetValueOnTreeItem v "Dynamic" SLSoluType

    # Time parameters
    set time_parameters [list EndTime 1.06 DeltaTime 0.01]
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
    $solidPartsNode setAttribute ov surface
    set props [list Element TotalLagrangianElement$nd ConstitutiveLaw LargeStrain3DLaw.SaintVenantKirchhoffModel]
    foreach {prop val} $props {
        set propnode [$solidPartsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Solid $prop"
        }
    }

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
    
    # Solid Loads
    GiD_Groups clone SelfWeight Total
    GiD_Groups edit parent Total SelfWeight 
    spdAux::AddIntervalGroup SelfWeight "SelfWeight//Total"
    GiD_Groups edit state "SelfWeight//Total" hidden
    set solidLoad "container\[@n='Solid'\]/container\[@n='Loads'\]/condition\[@n='SelfWeight$nd'\]"
    set solidLoadNode [customlib::AddConditionGroupOnXPath $solidLoad "SelfWeight//Total"]
    $solidLoadNode setAttribute ov surface
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
}
proc Solid::examples::TreeAssignationDynamicRod2Da {args} {
    Kratos::ResetModel
}
