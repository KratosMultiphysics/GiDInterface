
proc ::Solid::examples::NotchedBeam {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawNotchedBeamGeometry$::Model::SpatialDimension
    TreeAssignationNotchedBeam$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc Solid::examples::DrawNotchedBeamGeometry3D {args} {
    Kratos::ResetModel
}
proc Solid::examples::DrawNotchedBeamGeometry2D {args} {
    Kratos::ResetModel
    set dir [apps::getMyDir "Solid"]
    set problemfile [file join $dir examples NotchedBeam2D.gid]
    GiD_Process Mescape Files InsertGeom $problemfile
}
proc Solid::examples::DrawNotchedBeamGeometry2Da {args} {
    Kratos::ResetModel
}
# Mesh sizes


# Tree assign
proc Solid::examples::TreeAssignationNotchedBeam3D {args} {
    Kratos::ResetModel
}
proc Solid::examples::TreeAssignationNotchedBeam2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Quasi-static solution strategy set
    spdAux::SetValueOnTreeItem v "Quasi-static" SLSoluType
    spdAux::SetValueOnTreeItem v "Non-linear" SLAnalysisType

    # Time parameters
    set time_parameters [list EndTime 200 DeltaTime 1]
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
    set props [list Element SmallDisplacementElement$nd ConstitutiveLaw SmallStrainPlaneStress2DLaw.SimoJuExponentialDamageModel DENSITY 2500 YOUNG_MODULUS 2.8e10 POISSON_RATIO 0.1 THICKNESS 0.1 DAMAGE_THRESHOLD 19.1237 STRENGTH_RATIO 10.9375 FRACTURE_ENERGY 140]
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
    GiD_Groups clone ConstraintXY Total
    GiD_Groups edit parent Total ConstraintXY
    spdAux::AddIntervalGroup ConstraintXY "ConstraintXY//Total"
    GiD_Groups edit state "ConstraintXY//Total" hidden
    set solidConstraintXY {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintXYNode [customlib::AddConditionGroupOnXPath $solidConstraintXY "ConstraintXY//Total"]
    $solidConstraintXYNode setAttribute ov line
    set props [list Enabled_X Yes ByFunctionX No valueX 0.0 Enabled_Y Yes ByFunctionY No valueY 0.0 Enabled_Z Yes ByFunctionZ No valueZ 0.0]
    foreach {prop val} $props {
         set propnode [$solidConstraintXYNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    # Solid Constraint
    GiD_Groups clone ConstraintY Total
    GiD_Groups edit parent Total ConstraintY
    spdAux::AddIntervalGroup ConstraintY "ConstraintY//Total"
    GiD_Groups edit state "ConstraintY//Total" hidden
    set solidConstraintY {container[@n='Solid']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set solidConstraintYNode [customlib::AddConditionGroupOnXPath $solidConstraintY "ConstraintY//Total"]
    $solidConstraintYNode setAttribute ov line
    set props [list Enabled_X No ByFunctionX No valueX 0.0 Enabled_Y Yes ByFunctionY No valueY 0.0 Enabled_Z Yes ByFunctionZ No valueZ 0.0]
    foreach {prop val} $props {
         set propnode [$solidConstraintYNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }
    
    # Solid Loads
    GiD_Groups clone LoadY Total
    GiD_Groups edit parent Total LoadY 
    spdAux::AddIntervalGroup LoadY "LoadY//Total"
    GiD_Groups edit state "LoadY//Total" hidden
    set solidLoadY "container\[@n='Solid'\]/container\[@n='Loads'\]/condition\[@n='Load$nd'\]"
    set solidLoadYNode [customlib::AddConditionGroupOnXPath $solidLoadY "LoadY//Total"]
    $solidLoadYNode setAttribute ov line
    set props [list ByFunction Yes function_modulus "3000*t" direction 0.0,-1.0,0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$solidLoadYNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid $prop"
         }
    }

    GiD_Groups clone LoadYY Total
    GiD_Groups edit parent Total LoadYY 
    spdAux::AddIntervalGroup LoadYY "LoadYY//Total"
    GiD_Groups edit state "LoadYY//Total" hidden
    set solidLoadYY "container\[@n='Solid'\]/container\[@n='Loads'\]/condition\[@n='Load$nd'\]"
    set solidLoadYYNode [customlib::AddConditionGroupOnXPath $solidLoadYY "LoadYY//Total"]
    $solidLoadYYNode setAttribute ov line
    set props [list ByFunction Yes function_modulus "30000*t" direction 0.0,-1.0,0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$solidLoadYYNode selectNodes "./value\[@n = '$prop'\]"]
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
    # Output
    set output_parameters [list DAMAGE_VARIABLE Yes]
    set output_params_path [spdAux::getRoute "ElementResults"]
    foreach {n v} $output_parameters {
        [$root selectNodes "$output_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }
    spdAux::RequestRefresh
}
proc Solid::examples::TreeAssignationNotchedBeam2Da {args} {
    Kratos::ResetModel
}
