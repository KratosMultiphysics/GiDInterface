
proc ::Solid::examples::EccentricColumn {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawEccentricColumnGeometry$::Model::SpatialDimension
    TreeAssignationEccentricColumn$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc Solid::examples::DrawEccentricColumnGeometry3D {args} {
    Kratos::ResetModel
    set dir [apps::getMyDir "Solid"]
    set problemfile [file join $dir examples EccentricColumn3D.gid]
    GiD_Process Mescape Files InsertGeom $problemfile
}
proc Solid::examples::DrawEccentricColumnGeometry2Da {args} {
    Kratos::ResetModel
}
proc Solid::examples::DrawEccentricColumnGeometry2D {args} {
    Kratos::ResetModel
}
# Mesh sizes


# Tree assign
proc Solid::examples::TreeAssignationEccentricColumn3D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Static solution strategy set
    spdAux::SetValueOnTreeItem v "Static" SLSoluType

    # Time parameters
    set time_parameters [list EndTime 1.0 DeltaTime 1.0]
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
    set props [list Element SmallDisplacementElement$nd ConstitutiveLaw SmallStrain3DLaw.LinearElasticModel]
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
    GiD_Groups clone ConstraintX Total
    GiD_Groups edit parent Total ConstraintX
    spdAux::AddIntervalGroup ConstraintX "ConstraintX//Total"
    GiD_Groups edit state "ConstraintX//Total" hidden
    set solidConstraintX {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintXNode [customlib::AddConditionGroupOnXPath $solidConstraintX "ConstraintX//Total"]
    $solidConstraintXNode setAttribute ov line
    set props [list Enabled_X Yes ByFunctionX No valueX 0.0 Enabled_Y No ByFunctionY No valueY 0.0 Enabled_Z No ByFunctionZ No valueZ 0.0]
    foreach {prop val} $props {
         set propnode [$solidConstraintXNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    GiD_Groups clone ConstraintZ Total
    GiD_Groups edit parent Total ConstraintZ
    spdAux::AddIntervalGroup ConstraintZ "ConstraintZ//Total"
    GiD_Groups edit state "ConstraintZ//Total" hidden
    set solidConstraintZ {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintZNode [customlib::AddConditionGroupOnXPath $solidConstraintZ "ConstraintZ//Total"]
    $solidConstraintZNode setAttribute ov line
    set props [list Enabled_X No ByFunctionX No valueX 0.0 Enabled_Y No ByFunctionY No valueY 0.0 Enabled_Z Yes ByFunctionZ No valueZ 0.0]
    foreach {prop val} $props {
         set propnode [$solidConstraintZNode selectNodes "./value\[@n = '$prop'\]"]
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
    
    GiD_Groups clone Load Total
    GiD_Groups edit parent Total Load 
    spdAux::AddIntervalGroup Load "Load//Total"
    GiD_Groups edit state "Load//Total" hidden
    set solidLoad "container\[@n='Solid'\]/container\[@n='Loads'\]/condition\[@n='Load$nd'\]"
    set solidLoadNode [customlib::AddConditionGroupOnXPath $solidLoad "Load//Total"]
    $solidLoadNode setAttribute ov surface
    set props [list ByFunction No modulus 4.44e6 direction 0.0,-1.0,0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$solidLoadNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    GiD_Groups clone Spring Total
    GiD_Groups edit parent Total Spring 
    spdAux::AddIntervalGroup Spring "Spring//Total"
    GiD_Groups edit state "Spring//Total" hidden
    set solidSpring "container\[@n='Solid'\]/container\[@n='Loads'\]/condition\[@n='Spring$nd'\]"
    set solidSpringNode [customlib::AddConditionGroupOnXPath $solidSpring "Spring//Total"]
    $solidSpringNode setAttribute ov surface
    set props [list ByFunction No modulus 50e6 direction 0.0,1.0,0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$solidSpringNode selectNodes "./value\[@n = '$prop'\]"]
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
    
    # Solver
    set solver_parameters [list Solver AMGCL max_iteration 2000 tolerance 1e-6 krylov_type cg]
    set solver_params_path [spdAux::getRoute "SLStaticlinear_solver_settings"]
    foreach {n v} $solver_parameters {
        [$root selectNodes "$solver_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }
    
    spdAux::RequestRefresh
}
proc Solid::examples::TreeAssignationEccentricColumn2Da {args} {
    Kratos::ResetModel
}
proc Solid::examples::TreeAssignationEccentricColumn2D {args} {
    Kratos::ResetModel
}
