
proc ::Structural::examples::TrussCantilever {args} {
    DrawTrussCantileverGeometry
    AssignTrussCantileverMeshSizes
    TreeAssignationTrussCantilever
}

proc Structural::examples::DrawTrussCantileverGeometry {args} {
    Kratos::ResetModel
    set structure_layer Structure
    GiD_Process Mescape 'Layers ChangeName Layer0 $structure_layer escape

    # Geometry creation
    set coordinates [list 0 0 0 2 0 0 4 0 0 6 0 0 8 0 0 10 0 0 10 -5 0 8 -4 0 6 -3 0 4 -2 0 2 -1 0]
    set structurePoints [list ]
    foreach {x y z} $coordinates {
        lappend structurePoints [GiD_Geometry create point append $structure_layer $x $y $z]
    }

    set structureLines [list ]
    set initial [lindex $structurePoints 0]
    foreach point [lrange $structurePoints 1 end] {
        lappend structureLines [GiD_Geometry create line append stline $structure_layer $initial $point]
        set initial $point
    }
    lappend strucLines [GiD_Geometry create line append stline $structure_layer $initial [lindex $structurePoints 0]]

    lappend structureLines [GiD_Geometry create line append stline $structure_layer 2 11]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 11 3]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 3 10]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 10 4]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 4 9]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 9 5]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 5 8]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 8 6]
    
    GiD_Process 'Zoom Frame

    # Group creation
    GiD_Groups create Structure
    GiD_Groups create XYZ
    GiD_Groups create XZ
    GiD_Groups create Z
    GiD_Groups create Load
    
    GiD_EntitiesGroups assign Structure lines [GiD_EntitiesLayers get $structure_layer lines]
    GiD_EntitiesGroups assign XYZ points 6
    GiD_EntitiesGroups assign XZ points 7
    GiD_EntitiesGroups assign Z points {1 2 3 4 5 8 9 10 11}
    GiD_EntitiesGroups assign Load points {1 2 3 4 5}
    
    GidUtils::UpdateWindow GROUPS
}

proc Structural::examples::AssignTrussCantileverMeshSizes {args} {
    GiD_Process Mescape Meshing Structured Lines 1 {*}[GiD_EntitiesGroups get Structure lines] escape escape 
}


proc Structural::examples::TreeAssignationTrussCantilever {args} {
    return ""
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$::Model::SpatialDimension eq "3D"} { set condtype surface }

    # Fluid Parts
    set fluidParts {container[@n='FSI']/container[@n='Fluid']/condition[@n='Parts']}
    set fluidNode [spdAux::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 956.0 VISCOSITY 1.51670E-04 YIELD_STRESS 0 POWER_LAW_K 1 POWER_LAW_N 1]
    foreach {prop val} $props {
        set propnode [$fluidNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Fluid $prop"
        }
    }

    set fluidConditions {container[@n='FSI']/container[@n='Fluid']/container[@n='BoundaryConditions']}
    # Fluid Interface
    set fluidInlet "$fluidConditions/condition\[@n='AutomaticInlet$nd'\]"

    # Fluid Inlet
    set inletNode [spdAux::AddConditionGroupOnXPath $fluidInlet Inlet]
    $inletNode setAttribute ov $condtype
    set props [list ByFunction Yes function_modulus {0.1214*(1-cos(0.1*pi*t))*y*(1-y) if t<10 else 0.2428*y*(1-y)} direction automatic_inwards_normal Interval Total]
    foreach {prop val} $props {
         set propnode [$inletNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Inlet $prop"
        }
    }

    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [spdAux::AddConditionGroupOnXPath $fluidOutlet Outlet]
    $outletNode setAttribute ov $condtype
    set props [list value 0.0]
    foreach {prop val} $props {
         set propnode [$outletNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Outlet $prop"
        }
    }

    # Fluid Conditions
    [spdAux::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" NoSlip] setAttribute ov $condtype
    [spdAux::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Slip] setAttribute ov $condtype
    [spdAux::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='FluidNoSlipInterface$nd'\]" FluidInterface] setAttribute ov $condtype

    # Displacement 3D
    if {$nd eq "3D"} {
        set fluidDisplacement "$fluidConditions/condition\[@n='ALEMeshDisplacementBC3D'\]"
        set fluidDisplacementNode [spdAux::AddConditionGroupOnXPath $fluidDisplacement FluidFixedDisplacement_full]
        $fluidDisplacementNode setAttribute ov surface
        set props [list constrainedX 1 constrainedY 1 constrainedZ 1 valueX 0.0 valueY 0.0 valueZ 0.0 Interval Total]
        foreach {prop val} $props {
             set propnode [$fluidDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
             if {$propnode ne "" } {
                  $propnode setAttribute v $val
             } else {
                W "Warning - Couldn't find property FluidFixedDisplacement_full $prop"
             }
        }
        set fluidDisplacementNode [spdAux::AddConditionGroupOnXPath $fluidDisplacement FluidFixedDisplacement_lat]
        $fluidDisplacementNode setAttribute ov surface
        set props [list constrainedX 0 constrainedY 0 constrainedZ 1 valueX 0.0 valueY 0.0 valueZ 0.0 Interval Total]
        foreach {prop val} $props {
             set propnode [$fluidDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
             if {$propnode ne "" } {
                  $propnode setAttribute v $val
             } else {
                W "Warning - Couldn't find property FluidFixedDisplacement_lat $prop"
             }
        }
    } {
        set fluidDisplacement "$fluidConditions/condition\[@n='ALEMeshDisplacementBC2D'\]"
        set fluidDisplacementNode [spdAux::AddConditionGroupOnXPath $fluidDisplacement FluidALEMeshBC]
        $fluidDisplacementNode setAttribute ov line
        set props [list constrainedX 1 constrainedY 1 constrainedZ 1 valueX 0.0 valueY 0.0 valueZ 0.0 Interval Total]
        foreach {prop val} $props {
             set propnode [$fluidDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
             if {$propnode ne "" } {
                  $propnode setAttribute v $val
             } else {
                W "Warning - Couldn't find property ALEMeshDisplacementBC2D $prop"
             }
        }
    }

    # Fluid domain time parameters
    set change_list [list EndTime 25.0 DeltaTime 0.1]
    set xpath [spdAux::getRoute FLTimeParameters]
    foreach {name value} $change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check MOK script"
        }
    }

    # Fluid domain output parameters
    set change_list [list OutputControlType step]
    set xpath [spdAux::getRoute FLResults]
    foreach {name value} $change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check MOK script"
        }
    }

    # Fluid monolithic strategy setting
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid domain strategy settings
    set str_change_list [list relative_velocity_tolerance "1e-8" absolute_velocity_tolerance "1e-10" relative_pressure_tolerance "1e-8" absolute_pressure_tolerance "1e-10" maximum_iterations "20"]
    set xpath [spdAux::getRoute FLStratParams]
    foreach {name value} $str_change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check MOK script"
        }
    }

    # Structural
    gid_groups_conds::setAttributesF {container[@n='FSI']/container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Dynamic}

    # Structural Parts
    set structParts {container[@n='FSI']/container[@n='Structural']/condition[@n='Parts']}
    set structPartsNode [spdAux::AddConditionGroupOnXPath $structParts Structure]
    $structPartsNode setAttribute ov [expr {$nd == "3D" ? "volume" : "surface"}]
    set constLawNameStruc [expr {$nd == "3D" ? "LinearElastic3DLaw" : "LinearElasticPlaneStress2DLaw"}]
    set props [list Element TotalLagrangianElement$nd ConstitutiveLaw $constLawNameStruc THICKNESS 1.0 DENSITY 1500.0 VISCOSITY 1e-6]
    lappend props YIELD_STRESS 0 YOUNG_MODULUS 2.3e6 POISSON_RATIO 0.45
    foreach {prop val} $props {
         set propnode [$structPartsNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Structural Displacement
    set structDisplacement {container[@n='FSI']/container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [spdAux::AddConditionGroupOnXPath $structDisplacement FixedDisplacement]
    $structDisplacementNode setAttribute ov [expr {$nd == "3D" ? "surface" : "line"}]
    set props [list constrainedX Yes ByFunctionX No valueX 0.0 constrainedY Yes ByFunctionY No valueY 0.0 constrainedZ Yes ByFunctionZ No valueZ 0.0]
    foreach {prop val} $props {
         set propnode [$structDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Structural Interface
    spdAux::AddConditionGroupOnXPath "container\[@n='FSI'\]/container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='StructureInterface$nd'\]" StructureInterface

    # Structure domain time parameters
    set change_list [list EndTime 25.0 DeltaTime 0.1]
    set xpath [spdAux::getRoute STTimeParameters]
    foreach {name value} $change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check MOK script"
        }
    }

    # Structure domain output parameters
    set change_list [list OutputControlType step]
    set xpath [spdAux::getRoute STResults]
    foreach {name value} $change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check MOK script"
        }
    }

    # Structure Bossak scheme setting
    spdAux::SetValueOnTreeItem v "bossak" STScheme

    # Structure domain strategy settings
    set str_change_list [list residual_relative_tolerance "1e-8" residual_absolute_tolerance "1e-10" max_iteration "20"]
    set xpath [spdAux::getRoute STStratParams]
    foreach {name value} $str_change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check MOK script"
        }
    }

    # Coupling settings
    set parallelization_parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set parallelization_params_path [spdAux::getRoute "Parallelization"]
    foreach {n v} $parallelization_parameters {
        [$root selectNodes "$parallelization_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }

    set change_list [list nl_tol "1e-8" nl_max_it 25]
    set xpath [spdAux::getRoute FSIStratParams]
    foreach {name value} $change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check MOK script"
        }
    }

    set change_list [list Solver MVQN_recursive buffer_size 7]
    set xpath [spdAux::getRoute FSIDirichletNeumanncoupling_strategy]
    foreach {name value} $change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check MOK script"
        }
    }

    spdAux::RequestRefresh
}
