
proc FSI::examples::HighRiseBuilding {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawHighRiseBuildingGeometry
    AssignGroupsHighRiseBuilding$::Model::SpatialDimension
    AssignHighRiseBuildingMeshSizes
    TreeAssignationHighRiseBuilding

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

proc FSI::examples::DrawHighRiseBuildingGeometry {args} {
    Fluid::examples::DrawHighRiseBuildingGeometry$::Model::SpatialDimension
    Structural::examples::DrawHighRiseBuildingGeometry$::Model::SpatialDimension
}

proc FSI::examples::AssignGroupsHighRiseBuilding2D {args} {
    # Fluid group creation
    GiD_Groups create Fluid
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Inlet
    GiD_EntitiesGroups assign Inlet lines 8

    GiD_Groups create Outlet
    GiD_EntitiesGroups assign Outlet lines 6

    GiD_Groups create Top_Wall
    GiD_EntitiesGroups assign Top_Wall lines 7

    GiD_Groups create Bottom_Wall
    GiD_EntitiesGroups assign Bottom_Wall lines {1 5}

    GiD_Groups create InterfaceFluid
    GiD_EntitiesGroups assign InterfaceFluid lines {2 3 4}

    GiD_Groups create FluidALEMeshBC
    GiD_EntitiesGroups assign FluidALEMeshBC lines {1 5 6 7 8}

    # Structure group creation
    GiD_Groups create Structure
    GiD_Groups create Ground
    GiD_Groups create InterfaceStructure
    
    GiD_EntitiesGroups assign Structure surfaces 2
    GiD_EntitiesGroups assign Ground lines 12
    GiD_EntitiesGroups assign InterfaceStructure lines {9 10 11}
}

proc FSI::examples::AssignGroupsHighRiseBuilding3D {args} {
    # To be implemented
}

proc FSI::examples::AssignHighRiseBuildingMeshSizes {args} {
    Fluid::examples::AssignHighRiseBuildingMeshSizes$::Model::SpatialDimension
    Structural::examples::AssignHighRiseBuildingMeshSizes$::Model::SpatialDimension
}

proc FSI::examples::TreeAssignationHighRiseBuilding {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$::Model::SpatialDimension eq "3D"} { set condtype surface }

    # Fluid monolithic strategy setting
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid Parts
    set fluidParts {container[@n='FSI']/container[@n='Fluid']/condition[@n='Parts']}
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 1.225 DYNAMIC_VISCOSITY 1.846e-5]
    foreach {prop val} $props {
        set propnode [$fluidNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Fluid $prop"
        }
    }

    set fluidConditions {container[@n='FSI']/container[@n='Fluid']/container[@n='BoundaryConditions']}

    # Fluid Inlet
    Fluid::xml::CreateNewInlet Inlet {new true name inlet1 ini 0 end 10.0} true "25.0*t/10.0"
    Fluid::xml::CreateNewInlet Inlet {new true name inlet2 ini 10.0 end End} false 25.0
    
    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $fluidOutlet Outlet]
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
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Top_Wall] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Bottom_Wall] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='FluidNoSlipInterface$nd'\]" InterfaceFluid] setAttribute ov $condtype

    # Displacement 3D
    if {$nd eq "3D"} {
        # To be implemented
    } {
        GiD_Groups create "FluidALEMeshBC//Total"
        GiD_Groups edit state "FluidALEMeshBC//Total" hidden
        spdAux::AddIntervalGroup FluidALEMeshBC "FluidALEMeshBC//Total"
        set fluidDisplacement "$fluidConditions/condition\[@n='ALEMeshDisplacementBC2D'\]"
        set fluidDisplacementNode [customlib::AddConditionGroupOnXPath $fluidDisplacement "FluidALEMeshBC//Total"]
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

    # Time parameters
    set time_parameters [list EndTime 40.0 DeltaTime 0.05]
    set time_params_path [spdAux::getRoute "FLTimeParameters"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }

    # Output
    set params [list OutputControlType time OutputDeltaTime 1.0]
    set path "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    foreach {n v} $params {
        [$root selectNodes "$path/value\[@n = '$n'\]"] setAttribute v $v
    }

    # Fluid domain strategy settings
    set str_change_list [list relative_velocity_tolerance "1e-8" absolute_velocity_tolerance "1e-10" relative_pressure_tolerance "1e-8" absolute_pressure_tolerance "1e-10" maximum_iterations "20"]
    set xpath [spdAux::getRoute FLStratParams]
    foreach {name value} $str_change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check high-rise building script"
        }
    }

    # Structural
    gid_groups_conds::setAttributesF {container[@n='FSI']/container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Dynamic}

    # Structural Parts
    set structParts {container[@n='FSI']/container[@n='Structural']/condition[@n='Parts']}
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure]
    $structPartsNode setAttribute ov surface
    set constLawNameStruc "LinearElasticPlaneStress2DLaw"
    set props [list Element TotalLagrangianElement$nd ConstitutiveLaw $constLawNameStruc DENSITY 7850 YOUNG_MODULUS 206.9e9 POISSON_RATIO 0.29 THICKNESS 0.1]
    foreach {prop val} $props {
         set propnode [$structPartsNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Structural Displacement
    GiD_Groups clone Ground Total
    GiD_Groups edit parent Total Ground
    spdAux::AddIntervalGroup Ground "Ground//Total"
    GiD_Groups edit state "Ground//Total" hidden
    set structDisplacement {container[@n='FSI']/container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement Ground]
    $structDisplacementNode setAttribute ov line
    set props [list constrained Yes ByFunction No value 0.0]
    foreach {prop val} $props {
         set propnode [$structDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Structure domain time parameters
    set change_list [list EndTime 40.0 DeltaTime 0.05]
    set xpath [spdAux::getRoute STTimeParameters]
    foreach {name value} $change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check Truss example script"
        }
    }

    # Structural Interface
    customlib::AddConditionGroupOnXPath "container\[@n='FSI'\]/container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='StructureInterface$nd'\]" InterfaceStructure

    # Structure domain output parameters
    set change_list [list OutputControlType time OutputDeltaTime 1.0]
    set xpath "[spdAux::getRoute STResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    foreach {name value} $change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check high-rise building script"
        }
    }

    # Structure Bossak scheme setting
    spdAux::SetValueOnTreeItem v "bossak" STScheme

    # Structure domain strategy settings
    set str_change_list [list echo_level 0 residual_relative_tolerance "1e-8" residual_absolute_tolerance "1e-10" max_iteration "20"]
    set xpath [spdAux::getRoute STStratParams]
    foreach {name value} $str_change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check high-rise building script"
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
            W "Couldn't find $name - Check high-rise building script"
        }
    }

    set change_list [list Solver Relaxation]
    set xpath [spdAux::getRoute FSIPartitionedcoupling_strategy]
    foreach {name value} $change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check high-rise building script"
        }
    }

    spdAux::RequestRefresh
}
