
proc ::Solid::examples::CircularTank {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawCircularTankGeometry$::Model::SpatialDimension
    TreeAssignationCircularTank$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc Solid::examples::DrawCircularTankGeometry3D {args} {
    Kratos::ResetModel
    set dir [apps::getMyDir "Solid"]
    set problemfile [file join $dir examples CircularTank3D.gid]
    GiD_Process Mescape Files InsertGeom $problemfile
}
proc Solid::examples::DrawCircularTankGeometry2Da {args} {
    Kratos::ResetModel
    set dir [apps::getMyDir "Solid"]
    set problemfile [file join $dir examples CircularTank2Da.gid]
    GiD_Process Mescape Files InsertGeom $problemfile
}
proc Solid::examples::DrawCircularTankGeometry2D {args} {
    Kratos::ResetModel
}
# Mesh sizes


# Tree assign
proc Solid::examples::TreeAssignationCircularTank3D {args} {
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
    $solidConstraintXNode setAttribute ov surface
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
    $solidConstraintZNode setAttribute ov surface
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
    
    GiD_Groups clone Pressure Total
    GiD_Groups edit parent Total Pressure 
    spdAux::AddIntervalGroup Pressure "Pressure//Total"
    GiD_Groups edit state "Pressure//Total" hidden
    set solidPressure "container\[@n='Solid'\]/container\[@n='Loads'\]/condition\[@n='Pressure$nd'\]"
    set solidPressureNode [customlib::AddConditionGroupOnXPath $solidPressure "Pressure//Total"]
    $solidPressureNode setAttribute ov surface
    set props [list ByFunction Yes function_value "9.81*1000*(2.5-y)" Interval Total]
    foreach {prop val} $props {
         set propnode [$solidPressureNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    GiD_Groups clone Ballast Total
    GiD_Groups edit parent Total Ballast 
    spdAux::AddIntervalGroup Ballast "Ballast//Total"
    GiD_Groups edit state "Ballast//Total" hidden
    set solidBallast "container\[@n='Solid'\]/container\[@n='Loads'\]/condition\[@n='Ballast$nd'\]"
    set solidBallastNode [customlib::AddConditionGroupOnXPath $solidBallast "Ballast//Total"]
    $solidBallastNode setAttribute ov surface
    set props [list ByFunction No value 50e6 Interval Total]
    foreach {prop val} $props {
         set propnode [$solidBallastNode selectNodes "./value\[@n = '$prop'\]"]
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
proc Solid::examples::TreeAssignationCircularTank2Da {args} {
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
    $solidPartsNode setAttribute ov surface
    set props [list Element SmallDisplacementElement$nd ConstitutiveLaw SmallStrainAxisymmetric2DLaw.LinearElasticModel]
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
    set props [list Enabled_X Yes ByFunctionX No valueX 0.0 Enabled_Y No ByFunctionY No valueY 0.0 Enabled_Z No ByFunctionZ No valueZ 0.0]
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
    
    GiD_Groups clone Pressure Total
    GiD_Groups edit parent Total Pressure 
    spdAux::AddIntervalGroup Pressure "Pressure//Total"
    GiD_Groups edit state "Pressure//Total" hidden
    set solidPressure "container\[@n='Solid'\]/container\[@n='Loads'\]/condition\[@n='Pressure$nd'\]"
    set solidPressureNode [customlib::AddConditionGroupOnXPath $solidPressure "Pressure//Total"]
    $solidPressureNode setAttribute ov line
    set props [list ByFunction Yes function_value "9.81*1000*(2.5-y)" Interval Total]
    foreach {prop val} $props {
         set propnode [$solidPressureNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    GiD_Groups clone Ballast Total
    GiD_Groups edit parent Total Ballast 
    spdAux::AddIntervalGroup Ballast "Ballast//Total"
    GiD_Groups edit state "Ballast//Total" hidden
    set solidBallast "container\[@n='Solid'\]/container\[@n='Loads'\]/condition\[@n='Ballast$nd'\]"
    set solidBallastNode [customlib::AddConditionGroupOnXPath $solidBallast "Ballast//Total"]
    $solidBallastNode setAttribute ov line
    set props [list ByFunction No value 50e6 Interval Total]
    foreach {prop val} $props {
         set propnode [$solidBallastNode selectNodes "./value\[@n = '$prop'\]"]
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
proc Solid::examples::TreeAssignationCircularTank2D {args} {
    Kratos::ResetModel
}
